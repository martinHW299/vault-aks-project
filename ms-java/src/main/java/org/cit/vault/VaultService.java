package org.cit.vault;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class VaultService {
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    private final String vaultAddr;
    private final String roleId;
    private final String secretId;
    private final String secretsPath;

    private volatile String cachedToken;
    private volatile Instant cachedTokenExpiresAt = Instant.EPOCH;

    public VaultService(
            ObjectMapper objectMapper,
            @Value("${vault.addr}") String vaultAddr,
            @Value("${vault.role-id}") String roleId,
            @Value("${vault.secret-id}") String secretId,
            @Value("${vault.secrets-path}") String secretsPath
    ) {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.objectMapper = objectMapper;
        this.vaultAddr = stripTrailingSlash(vaultAddr);
        this.roleId = roleId;
        this.secretId = secretId;
        this.secretsPath = secretsPath.startsWith("/") ? secretsPath.substring(1) : secretsPath;
    }

    public Map<String, Object> readSecret() {
        String token = ensureToken();
        JsonNode response = vaultGet("/v1/" + secretsPath, token);

        JsonNode data = response.path("data");
        if (data.isMissingNode() || !data.isObject()) {
            return Map.of("raw", response);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        data.fields().forEachRemaining(e -> result.put(e.getKey(), e.getValue().isValueNode() ? e.getValue().asText() : e.getValue()));
        return result;
    }

    public Map<String, Object> health() {
        JsonNode response = vaultGet("/v1/sys/health", null);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("initialized", response.path("initialized").asBoolean(false));
        out.put("sealed", response.path("sealed").asBoolean(true));
        out.put("version", response.path("version").asText(""));
        return out;
    }

    private synchronized String ensureToken() {
        if (cachedToken != null && Instant.now().isBefore(cachedTokenExpiresAt.minusSeconds(30))) {
            return cachedToken;
        }
        if (roleId == null || roleId.isBlank() || secretId == null || secretId.isBlank()) {
            throw new IllegalStateException("Vault AppRole env vars missing: set VAULT_ROLE_ID and VAULT_SECRET_ID");
        }

        String body;
        try {
            body = objectMapper.writeValueAsString(Map.of("role_id", roleId, "secret_id", secretId));
        } catch (IOException e) {
            throw new RuntimeException("Failed to build Vault login request", e);
        }

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(vaultAddr + "/v1/auth/approle/login"))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Vault login request interrupted", e);
        } catch (IOException e) {
            throw new RuntimeException("Vault login request failed", e);
        }

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new RuntimeException("Vault login failed (HTTP " + response.statusCode() + "): " + response.body());
        }

        JsonNode root = readJson(response.body());
        String token = root.path("auth").path("client_token").asText(null);
        long leaseDurationSeconds = root.path("auth").path("lease_duration").asLong(0);
        if (token == null || token.isBlank()) {
            throw new RuntimeException("Vault login response missing auth.client_token");
        }

        cachedToken = token;
        cachedTokenExpiresAt = Instant.now().plusSeconds(Math.max(leaseDurationSeconds, 60));
        return token;
    }

    private JsonNode vaultGet(String path, String token) {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(vaultAddr + path))
                .timeout(Duration.ofSeconds(10))
                .GET();
        if (token != null && !token.isBlank()) {
            builder.header("X-Vault-Token", token);
        }
        HttpRequest request = builder.build();

        HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Vault GET interrupted: " + path, e);
        } catch (IOException e) {
            throw new RuntimeException("Vault GET failed: " + path, e);
        }

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new RuntimeException("Vault GET failed (HTTP " + response.statusCode() + ") for " + path + ": " + response.body());
        }
        return readJson(response.body());
    }

    private JsonNode readJson(String body) {
        try {
            return objectMapper.readTree(body);
        } catch (IOException e) {
            throw new RuntimeException("Invalid JSON from Vault: " + body, e);
        }
    }

    private static String stripTrailingSlash(String s) {
        if (s == null) return null;
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }
}
