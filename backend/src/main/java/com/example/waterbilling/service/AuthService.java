package com.example.waterbilling.service;

import com.example.waterbilling.dto.ChangePasswordRequest;
import com.example.waterbilling.dto.LoginRequest;
import com.example.waterbilling.dto.LoginResponse;
import com.example.waterbilling.dto.UpdateProfileRequest;
import com.example.waterbilling.dto.UserDto;
import com.example.waterbilling.entity.AppUser;
import com.example.waterbilling.repository.AppUserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Base64;
import java.util.UUID;

@Service
public class AuthService {
    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(AppUserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public LoginResponse login(LoginRequest request) {
        AppUser user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new IllegalArgumentException("Sai tài khoản hoặc mật khẩu"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Sai tài khoản hoặc mật khẩu");
        }

        String token = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString((user.getUsername() + ":" + UUID.randomUUID()).getBytes());
        return new LoginResponse(token, UserDto.from(user));
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        AppUser user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tài khoản"));
        if (!passwordEncoder.matches(request.oldPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Mật khẩu hiện tại không đúng");
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
    }

    @Transactional
    public UserDto updateProfile(UpdateProfileRequest request) {
        AppUser user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tài khoản"));
        user.setFullName(request.fullName());
        user.setEmail(request.email());
        user.setPhone(request.phone());
        return UserDto.from(userRepository.save(user));
    }
}
