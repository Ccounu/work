package com.example.railway.dto;

import java.math.BigDecimal;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

public class PaymentCallbackRequest {

    @NotBlank
    @Size(max = 40)
    private String paymentNo;

    @NotBlank
    @Size(max = 64)
    private String callbackRequestId;

    @NotNull
    private Boolean success;

    @Size(max = 64)
    private String channelPaymentNo;

    @NotNull
    private BigDecimal amount;

    @NotBlank
    @Size(max = 32)
    private String timestamp;

    @NotBlank
    @Size(max = 128)
    private String signature;

    @Size(max = 200)
    private String message;

    public String getPaymentNo() {
        return paymentNo;
    }

    public void setPaymentNo(String paymentNo) {
        this.paymentNo = paymentNo;
    }

    public String getCallbackRequestId() {
        return callbackRequestId;
    }

    public void setCallbackRequestId(String callbackRequestId) {
        this.callbackRequestId = callbackRequestId;
    }

    public Boolean getSuccess() {
        return success;
    }

    public void setSuccess(Boolean success) {
        this.success = success;
    }

    public String getChannelPaymentNo() {
        return channelPaymentNo;
    }

    public void setChannelPaymentNo(String channelPaymentNo) {
        this.channelPaymentNo = channelPaymentNo;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getSignature() {
        return signature;
    }

    public void setSignature(String signature) {
        this.signature = signature;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
