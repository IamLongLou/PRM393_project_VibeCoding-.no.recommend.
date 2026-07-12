package com.example.waterbilling.service;

import com.example.waterbilling.dto.BillDto;
import com.example.waterbilling.dto.MeterReadingRequest;
import com.example.waterbilling.dto.SyncRequest;
import com.example.waterbilling.entity.Bill;
import com.example.waterbilling.entity.CollectionStatus;
import com.example.waterbilling.entity.Customer;
import com.example.waterbilling.repository.BillRepository;
import com.example.waterbilling.repository.TariffTierRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class BillingService {
    private final BillRepository billRepository;
    private final CustomerService customerService;
    private final TariffTierRepository tariffTierRepository;

    public BillingService(BillRepository billRepository, CustomerService customerService, TariffTierRepository tariffTierRepository) {
        this.billRepository = billRepository;
        this.customerService = customerService;
        this.tariffTierRepository = tariffTierRepository;
    }

    @Transactional(readOnly = true)
    public List<BillDto> getAll() {
        return billRepository.findAllByOrderByDateDesc().stream().map(BillDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<BillDto> getByCustomer(Long customerId) {
        return billRepository.findByCustomerIdOrderByDateDesc(customerId).stream().map(BillDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<BillDto> getUnsynced() {
        return billRepository.findBySyncedFalseOrderByDateDesc().stream().map(BillDto::from).toList();
    }

    @Transactional
    public BillDto createFromMeterReading(Long customerId, MeterReadingRequest request) {
        Customer customer = customerService.findEntity(customerId);
        if (request.newReading() < customer.getCurrentReading()) {
            throw new IllegalArgumentException("Chỉ số mới không được nhỏ hơn chỉ số cũ");
        }

        int consumption = request.newReading() - customer.getCurrentReading();
        BigDecimal total = calculateTieredAmount(consumption).setScale(2, RoundingMode.HALF_UP);
        // Flutter gom VAT 5% + Phí BVMT 10% vào 1 trường (15% tổng)
        BigDecimal baseAmount = total.divide(BigDecimal.valueOf(1.15), 2, RoundingMode.HALF_UP);
        BigDecimal vatAndEnvFee = total.subtract(baseAmount).setScale(2, RoundingMode.HALF_UP);

        // unitPrice = average price per m3 (for display only)
        BigDecimal unitPrice = consumption > 0
                ? baseAmount.divide(BigDecimal.valueOf(consumption), 2, RoundingMode.HALF_UP)
                : BigDecimal.valueOf(12000).setScale(2, RoundingMode.HALF_UP);

        Bill bill = new Bill();
        bill.setCustomer(customer);
        bill.setBillCode(nextBillCode(customer));
        bill.setDate(LocalDateTime.now());
        bill.setOldReading(customer.getCurrentReading());
        bill.setNewReading(request.newReading());
        bill.setConsumption(BigDecimal.valueOf(consumption).setScale(2, RoundingMode.HALF_UP));
        bill.setUnitPrice(unitPrice);
        bill.setAmount(baseAmount);
        bill.setVat(vatAndEnvFee);
        bill.setTotalAmount(total);
        bill.setImagePath(request.imagePath());
        bill.setSynced(false);

        customer.setCurrentReading(request.newReading());
        customer.setStatus(CollectionStatus.COMPLETED);

        return BillDto.from(billRepository.save(bill));
    }

    @Transactional
    public List<BillDto> sync(SyncRequest request) {
        return request.bills().stream().map(this::upsertSyncedBill).toList();
    }

    @Transactional
    public BillDto markSynced(Long id) {
        Bill bill = billRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn id=" + id));
        bill.setSynced(true);
        return BillDto.from(bill);
    }

    /**
     * Tính tiền nước theo biểu giá lũy kế bậc thang.
     * Khớp hoàn toàn với logic trong Flutter BillingService.calculateAmount().
     * Bậc 1: 0-10 m³ x 5,973đ; Bậc 2: 11-20 m³ x 7,052đ;
     * Bậc 3: 21-30 m³ x 8,669đ; Bậc 4: >30 m³ x 15,929đ.
     * Cộng thêm 5% VAT + 10% Phí BVMT = 15% tổng.
     */
    private BigDecimal calculateTieredAmount(int consumption) {
        if (consumption <= 0) return BigDecimal.ZERO;

        // Giá bậc thang cố định (khớp với Flutter BillingService)
        final double P1 = 5973, P2 = 7052, P3 = 8669, P4 = 15929;
        double base;
        if (consumption <= 10) {
            base = consumption * P1;
        } else if (consumption <= 20) {
            base = 10 * P1 + (consumption - 10) * P2;
        } else if (consumption <= 30) {
            base = 10 * P1 + 10 * P2 + (consumption - 20) * P3;
        } else {
            base = 10 * P1 + 10 * P2 + 10 * P3 + (consumption - 30) * P4;
        }
        // 5% VAT + 10% BVMT = 15%
        return BigDecimal.valueOf(base * 1.15);
    }

    private BillDto upsertSyncedBill(BillDto dto) {
        Bill bill = billRepository.findByBillCode(dto.billCode()).orElseGet(Bill::new);
        Customer customer = customerService.findEntity(dto.customerId());

        bill.setCustomer(customer);
        bill.setBillCode(dto.billCode());
        bill.setDate(dto.date() == null ? LocalDateTime.now() : dto.date());
        bill.setOldReading(dto.oldReading());
        bill.setNewReading(dto.newReading());
        bill.setConsumption(dto.consumption());
        bill.setUnitPrice(dto.unitPrice());
        bill.setAmount(dto.amount());
        bill.setVat(dto.vat());
        bill.setTotalAmount(dto.totalAmount());
        bill.setImagePath(dto.imagePath());
        bill.setSynced(true);
        // Đồng bộ trạng thái thanh toán từ Flutter (mặc định false nếu null)
        bill.setPaid(dto.isPaid() != null && dto.isPaid());

        if (dto.newReading() > customer.getCurrentReading()) {
            customer.setCurrentReading(dto.newReading());
            customer.setStatus(CollectionStatus.COMPLETED);
        }

        return BillDto.from(billRepository.save(bill));
    }

    private String nextBillCode(Customer customer) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        return "HD" + timestamp + customer.getCode();
    }
}
