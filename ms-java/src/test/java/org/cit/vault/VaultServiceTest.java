package org.cit.vault;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertThrows;

class VaultServiceTest {
    @Test
    void throwsWhenMissingApproleEnv() {
        VaultService svc = new VaultService(
                new ObjectMapper(),
                "http://localhost:8200",
                "",
                "",
                "secret/myapp/test"
        );

        assertThrows(IllegalStateException.class, svc::readSecret);
    }
}

