package com.example.waterbilling.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Request đổi mật khẩu.")
public record ChangePasswordRequest(
        @Schema(description = "Username của người dùng.", example = "nhanvien01")
        @NotBlank(message = "username không được để trống")
        String username,

        @Schema(description = "Mật khẩu hiện tại.", example = "123456")
        @NotBlank(message = "oldPassword không được để trống")
        String oldPassword,

        @Schema(description = "Mật khẩu mới (tối thiểu 6 ký tự).", example = "newpass123")
        @NotBlank(message = "newPassword không được để trống")
        @Size(min = 6, message = "Mật khẩu mới phải có ít nhất 6 ký tự")
        String newPassword
) {}
