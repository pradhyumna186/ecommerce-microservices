package com.ecommerce.order.client;

import org.springframework.beans.factory.annotation.Autowired;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.Map;

@Component
public class ProductClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    private static final String PRODUCT_SERVICE_URL = "http://product-service:8082";
    private static final Logger LOGGER = LoggerFactory.getLogger(ProductClient.class);
    
    public ProductInfo getProductInfo(Long productId) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId;
        try {
            ApiResponse response = restTemplate.getForObject(url, ApiResponse.class);
            if (response == null || !response.isSuccess() || response.getData() == null) {
                return null;
            }
            return convertToProductInfo(response.getData());
        } catch (Exception e) {
            LOGGER.error("getProductInfo failed for productId {} via URL {}: {}", productId, url, e.toString());
            return null;
        }
    }
    
    public boolean checkProductAvailability(Long productId, Integer quantity) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId + "/availability?quantity=" + quantity;
        try {
            ApiResponse response = restTemplate.getForObject(url, ApiResponse.class);
            if (response == null || !response.isSuccess() || response.getData() == null) {
                return false;
            }
            Object data = response.getData();
            if (data instanceof Boolean) {
                return (Boolean) data;
            }
            return Boolean.parseBoolean(String.valueOf(data));
        } catch (Exception e) {
            LOGGER.error("checkProductAvailability failed for productId {} qty {} via URL {}: {}", productId, quantity, url, e.toString());
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
        if (!(data instanceof Map)) {
            return null;
        }
        Map<String, Object> dataMap = (Map<String, Object>) data;
        ProductInfo productInfo = new ProductInfo();
        Object idVal = dataMap.get("id");
        if (idVal instanceof Number) {
            productInfo.setId(((Number) idVal).longValue());
        } else if (idVal != null) {
            try { productInfo.setId(Long.parseLong(String.valueOf(idVal))); } catch (Exception ignored) {}
        }
        productInfo.setName((String) dataMap.get("name"));
        Object priceVal = dataMap.get("price");
        if (priceVal != null) {
            productInfo.setPrice(new BigDecimal(String.valueOf(priceVal)));
        }
        Object stockVal = dataMap.get("stockQuantity");
        if (stockVal instanceof Number) {
            productInfo.setStockQuantity(((Number) stockVal).intValue());
        } else if (stockVal != null) {
            try { productInfo.setStockQuantity(Integer.parseInt(String.valueOf(stockVal))); } catch (Exception ignored) {}
        }
        Object activeVal = dataMap.get("active");
        if (activeVal instanceof Boolean) {
            productInfo.setActive((Boolean) activeVal);
        } else if (activeVal != null) {
            productInfo.setActive(Boolean.parseBoolean(String.valueOf(activeVal)));
        }
        return productInfo;
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