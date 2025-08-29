package com.ecommerce.order.client;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;

@Component
public class ProductClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    private static final String PRODUCT_SERVICE_URL = "http://product-service";
    
    public ProductInfo getProductInfo(Long productId) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId;
        try {
            return restTemplate.getForObject(url, ProductInfo.class);
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch product information for product ID: " + productId);
        }
    }
    
    public boolean checkProductAvailability(Long productId, Integer quantity) {
        String url = PRODUCT_SERVICE_URL + "/api/products/" + productId + "/availability?quantity=" + quantity;
        try {
            return restTemplate.getForObject(url, Boolean.class);
        } catch (Exception e) {
            return false;
        }
    }
    
    public static class ProductInfo {
        private Long id;
        private String name;
        private BigDecimal price;
        private Integer stockQuantity;
        private Boolean active;
        
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
        
        public Boolean getActive() {
            return active;
        }
        
        public void setActive(Boolean active) {
            this.active = active;
        }
    }
}