package com.ecommerce.product.service;

import com.ecommerce.common.exception.BadRequestException;
import com.ecommerce.common.exception.ResourceNotFoundException;
import com.ecommerce.product.dto.ProductDto;
import com.ecommerce.product.dto.ProductResponseDto;
import com.ecommerce.product.entity.Category;
import com.ecommerce.product.entity.Product;
import com.ecommerce.product.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Autowired
    private CategoryService categoryService;
    
    public ProductResponseDto createProduct(ProductDto productDto) {
        Category category = categoryService.getCategoryById(productDto.getCategoryId());
        
        Product product = new Product(
            productDto.getName(),
            productDto.getDescription(),
            productDto.getPrice(),
            productDto.getStockQuantity(),
            category
        );
        product.setImageUrl(productDto.getImageUrl());
        
        Product savedProduct = productRepository.save(product);
        return convertToResponseDto(savedProduct);
    }
    
    public ProductResponseDto getProductById(Long id) {
        Product product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        return convertToResponseDto(product);
    }
    
    public Page<ProductResponseDto> getAllProducts(Pageable pageable) {
        return productRepository.findAllActive(pageable)
            .map(this::convertToResponseDto);
    }
    
    public List<ProductResponseDto> getProductsByCategory(Long categoryId) {
        return productRepository.findByCategoryId(categoryId).stream()
            .map(this::convertToResponseDto)
            .collect(Collectors.toList());
    }
    
    public Page<ProductResponseDto> searchProducts(String searchTerm, Pageable pageable) {
        return productRepository.searchActiveProducts(searchTerm, pageable)
            .map(this::convertToResponseDto);
    }
    
    public ProductResponseDto updateProduct(Long id, ProductDto productDto) {
        Product product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        
        Category category = categoryService.getCategoryById(productDto.getCategoryId());
        
        product.setName(productDto.getName());
        product.setDescription(productDto.getDescription());
        product.setPrice(productDto.getPrice());
        product.setStockQuantity(productDto.getStockQuantity());
        product.setImageUrl(productDto.getImageUrl());
        product.setCategory(category);
        
        Product updatedProduct = productRepository.save(product);
        return convertToResponseDto(updatedProduct);
    }
    
    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        product.setActive(false);
        productRepository.save(product);
    }
    
    public ProductResponseDto updateStock(Long productId, Integer newStock) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        if (newStock < 0) {
            throw new BadRequestException("Stock quantity cannot be negative");
        }
        
        product.setStockQuantity(newStock);
        Product updatedProduct = productRepository.save(product);
        return convertToResponseDto(updatedProduct);
    }
    
    public boolean isProductAvailable(Long productId, Integer quantity) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        return product.getActive() && product.getStockQuantity() >= quantity;
    }
    
    private ProductResponseDto convertToResponseDto(Product product) {
        ProductResponseDto dto = new ProductResponseDto();
        dto.setId(product.getId());
        dto.setName(product.getName());
        dto.setDescription(product.getDescription());
        dto.setPrice(product.getPrice());
        dto.setStockQuantity(product.getStockQuantity());
        dto.setImageUrl(product.getImageUrl());
        dto.setActive(product.getActive());
        dto.setCategoryId(product.getCategory().getId());
        dto.setCategoryName(product.getCategory().getName());
        dto.setCreatedAt(product.getCreatedAt());
        dto.setUpdatedAt(product.getUpdatedAt());
        return dto;
    }
}