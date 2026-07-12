package com.example.waterbilling.controller;

import com.example.waterbilling.dto.ChangePasswordRequest;
import com.example.waterbilling.dto.LoginRequest;
import com.example.waterbilling.dto.LoginResponse;
import com.example.waterbilling.dto.UpdateProfileRequest;
import com.example.waterbilling.dto.UserDto;
import com.example.waterbilling.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Authentication", description = "Đăng nhập và lấy thông tin người dùng cho app Flutter.")
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @Operation(
            summary = "Đăng nhập",
            description = """
                    Kiểm tra username/password trong bảng app_users.
                    Nếu hợp lệ, API trả về token demo và thông tin người dùng gồm username, fullName, role, email, phone.

                    Tài khoản mẫu sau khi chạy backend:
                    admin/admin123, nhanvien01/123456, khachhang01/654321, abc/123.
                    """
    )
    @ApiResponse(responseCode = "200", description = "Đăng nhập thành công.")
    @ApiResponse(responseCode = "400", description = "Sai tài khoản, mật khẩu hoặc request thiếu dữ liệu.")
    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @Operation(
            summary = "Đổi mật khẩu",
            description = """
                    Đổi mật khẩu cho người dùng. Yêu cầu cung cấp username, mật khẩu hiện tại và mật khẩu mới.
                    Trả về 200 nếu thành công, 400 nếu sai mật khẩu hiện tại.
                    """
    )
    @ApiResponse(responseCode = "200", description = "Đổi mật khẩu thành công.")
    @ApiResponse(responseCode = "400", description = "Sai mật khẩu hiện tại hoặc dữ liệu không hợp lệ.")
    @PostMapping("/change-password")
    public ResponseEntity<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(request);
        return ResponseEntity.ok().build();
    }

    @Operation(
            summary = "Cập nhật thông tin cá nhân",
            description = """
                    Cập nhật họ tên, email, số điện thoại của người dùng.
                    Trả về thông tin người dùng mới sau khi cập nhật.
                    """
    )
    @ApiResponse(responseCode = "200", description = "Cập nhật thành công.")
    @ApiResponse(responseCode = "400", description = "Không tìm thấy người dùng hoặc dữ liệu không hợp lệ.")
    @PostMapping("/update-profile")
    public UserDto updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        return authService.updateProfile(request);
    }
}
