package com.example.waterbilling.dto;

import com.example.waterbilling.entity.Bill;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Schema(description = "Thông tin hóa đơn nước sau khi ghi chỉ số hoặc đồng bộ.")
public record BillDto(
        @Schema(description = "ID hóa đơn do SQL Server tự sinh.", example = "1")
        Long id,
        @Schema(description = "ID khách hàng sở hữu hóa đơn.", example = "1")
        Long customerId,
        @Schema(description = "Tên khách hàng. Field này chủ yếu dùng cho response hiển thị.", example = "Lưu Bị")
        String customerName,
        @Schema(description = "Mã khách hàng. Field này chủ yếu dùng cho response hiển thị.", example = "KH001")
        String customerCode,
        @Schema(description = "Mã hóa đơn duy nhất.", example = "HD202406150001")
        String billCode,
        @Schema(description = "Ngày giờ lập hóa đơn.", example = "2024-06-05T14:31:00")
        LocalDateTime date,
        @Schema(description = "Chỉ số cũ.", example = "125")
        Integer oldReading,
        @Schema(description = "Chỉ số mới.", example = "150")
        Integer newReading,
        @Schema(description = "Số m3 tiêu thụ = newReading - oldReading.", example = "25.00")
        BigDecimal consumption,
        @Schema(description = "Đơn giá tính tiền nước.", example = "12000.00")
        BigDecimal unitPrice,
        @Schema(description = "Tiền nước trước VAT.", example = "300000.00")
        BigDecimal amount,
        @Schema(description = "Tiền VAT.", example = "30000.00")
        BigDecimal vat,
        @Schema(description = "Tổng tiền phải thanh toán.", example = "330000.00")
        BigDecimal totalAmount,
        @Schema(description = "Đường dẫn ảnh đồng hồ nước nếu app có upload/lưu ảnh.", example = "/images/meter-1.jpg")
        String imagePath,
        @Schema(description = "true nếu hóa đơn đã đồng bộ lên server, false nếu còn pending.", example = "false")
        Boolean isSynced,
        @Schema(description = "true nếu khách hàng đã thanh toán hóa đơn này.", example = "false")
        Boolean isPaid
) {
    public static BillDto from(Bill bill) {
        return new BillDto(
                bill.getId(),
                bill.getCustomer().getId(),
                bill.getCustomer().getName(),
                bill.getCustomer().getCode(),
                bill.getBillCode(),
                bill.getDate(),
                bill.getOldReading(),
                bill.getNewReading(),
                bill.getConsumption(),
                bill.getUnitPrice(),
                bill.getAmount(),
                bill.getVat(),
                bill.getTotalAmount(),
                bill.getImagePath(),
                bill.getSynced(),
                bill.getPaid()
        );
    }
}
