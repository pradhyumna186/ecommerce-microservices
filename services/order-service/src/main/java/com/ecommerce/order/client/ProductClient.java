package com.ecommerce.order.client;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.Map;

@Component
public class ProductClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    private static final String PRODUCT_SERVICE_URL = "http://product-service";
    
    public ProductInfo getProductInfo(Long productId) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId;
        try {
            ApiResponse response = restTemplate.getForObject(url, ApiResponse.class);
            if (response != null && response.isSuccess() && response.getData() != null) {
                // Convert the data map to ProductInfo
                return convertToProductInfo(response.getData());
            }
            return null;
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch product information for product ID: " + productId);
        }
    }
    
    public boolean checkProductAvailability(Long productId, Integer quantity) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId + "/availability?quantity=" + quantity;
        try {
            ApiResponse response = restTemplate.getForObject(url, ApiResponse.class);
            if (response != null && response.isSuccess() && response.getData() != null) {
                return (Boolean) response.getData();
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    public static class ProductInfo {
        private Long id;
        private String name;
        private BigDecimal price;
        private Integer stockQuantity;
        private boolean active;
        
        public ProductInfo() {}
        
        public Long getId() {
            return id;
        }
        
        public void setId(Long id) {
            this.id = id;
        }
        
        public String getName() {
            return name;
        }
        
        public void setName(String name) {
            this.name = name;
        }
        
        public BigDecimal getPrice() {
            return price;
        }
        
        public void setPrice(BigDecimal price) {
            this.price = price;
        }
        
        public Integer getStockQuantity() {
            return stockQuantity;
        }
        
        public void setStockQuantity(Integer stockQuantity) {
            this.stockQuantity = stockQuantity;
        }
        
        public boolean isActive() {
            return active;
        }
        
        public void setActive(boolean active) {
            this.active = active;
        }
    }
    
    private ProductInfo convertToProductInfo(Object data) {
        if (data instanceof Map) {
            Map<String, Object> dataMap = (Map<String, Object>) data;
            ProductInfo productInfo = new ProductInfo();
            productInfo.setId(((Number) dataMap.get("id")).longValue());
            productInfo.setName((String) dataMap.get("name"));
            productInfo.setPrice(new BigDecimal(dataMap.get("price").toString()));
            productInfo.setStockQuantity((Integer) dataMap.get("stockQuantity"));
            productInfo.setActive((Boolean) dataMap.get("active"));
            return productInfo;
        }
        return null;
    }
    
    public static class ApiResponse {
        private boolean success;
        private String message;
        private Object data;
        private String timestamp;
        
        public ApiResponse() {}
        
        public boolean isSuccess() {
            return success;
        }
        
        public void setSuccess(boolean success) {
            this.success = success;
        }
        
        public String getMessage() {
            return message;
        }
        
        public void setMessage(String message) {
            this.message = message;
        }
        
        public Object getData() {
            return data;
        }
        
        public void setData(Object data) {
            this.data = data;
        }
        
        public String getTimestamp() {
            return timestamp;
        }
        
        public void setTimestamp(String timestamp) {
            this.timestamp = timestamp;
        }
    }
}