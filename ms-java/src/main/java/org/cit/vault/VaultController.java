package org.cit.vault;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/vault")
public class VaultController {
    private final VaultService vaultService;

    public VaultController(VaultService vaultService) {
        this.vaultService = vaultService;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return vaultService.health();
    }

    @GetMapping("/secret")
    public ResponseEntity<?> secret() {
        return ResponseEntity.ok(vaultService.readSecret());
    }
}

