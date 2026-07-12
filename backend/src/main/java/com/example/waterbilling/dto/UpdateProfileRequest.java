package com.example.waterbilling.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Request cập nhật thông tin cá nhân.")
public record UpdateProfileRequest(
        @Schema(description = "Username của người dùng.", example = "nhanvien01")
        @NotBlank(message = "username không được để trống")
        String username,

        @Schema(description = "Họ tên mới.", example = "Nguyễn Văn B")
        @NotBlank(message = "Họ tên không được để trống")
        String fullName,

        @Schema(description = "Email mới.", example = "nhanvien@water.com")
        String email,

        @Schema(description = "Số điện thoại mới.", example = "0987654321")
        String phone
) {}
