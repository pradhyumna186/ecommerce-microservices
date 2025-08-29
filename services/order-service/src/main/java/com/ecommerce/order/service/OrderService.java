package com.ecommerce.order.service;

import com.ecommerce.common.exception.BadRequestException;
import com.ecommerce.common.exception.ResourceNotFoundException;
import com.ecommerce.order.client.ProductClient;
import com.ecommerce.order.dto.OrderDto;
import com.ecommerce.order.dto.OrderItemDto;
import com.ecommerce.order.dto.OrderItemResponseDto;
import com.ecommerce.order.dto.OrderResponseDto;
import com.ecommerce.order.entity.Order;
import com.ecommerce.order.entity.OrderItem;
import com.ecommerce.order.entity.OrderStatus;
import com.ecommerce.order.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class OrderService {
    
    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private ProductClient productClient;
    
    public OrderResponseDto createOrder(OrderDto orderDto) {
        List<OrderItem> orderItems = new ArrayList<>();
        BigDecimal totalAmount = BigDecimal.ZERO;
        
        Order order = new Order(
            orderDto.getUserId(),
            BigDecimal.ZERO,
            orderDto.getShippingAddress(),
            orderDto.getBillingAddress() != null ? orderDto.getBillingAddress() : orderDto.getShippingAddress()
        );
        
        for (OrderItemDto itemDto : orderDto.getOrderItems()) {
            ProductClient.ProductInfo productInfo = productClient.getProductInfo(itemDto.getProductId());
            
            if (productInfo == null || !productInfo.getActive()) {
                throw new BadRequestException("Product with ID " + itemDto.getProductId() + " is not available");
            }
            
            if (!productClient.checkProductAvailability(itemDto.getProductId(), itemDto.getQuantity())) {
                throw new BadRequestException("Insufficient stock for product: " + productInfo.getName());
            }
            
            OrderItem orderItem = new OrderItem(
                productInfo.getId(),
                productInfo.getName(),
                itemDto.getQuantity(),
                productInfo.getPrice(),
                order
            );
            
            orderItems.add(orderItem);
            totalAmount = totalAmount.add(orderItem.getTotalPrice());
        }
        
        order.setTotalAmount(totalAmount);
        order.setOrderItems(orderItems);
        
        Order savedOrder = orderRepository.save(order);
        return convertToResponseDto(savedOrder);
    }
    
    public OrderResponseDto getOrderById(Long id) {
        Order order = orderRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Order", "id", id));
        return convertToResponseDto(order);
    }
    
    public List<OrderResponseDto> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
            .map(this::convertToResponseDto)
            .collect(Collectors.toList());
    }
    
    public Page<OrderResponseDto> getOrdersByUserId(Long userId, Pageable pageable) {
        return orderRepository.findByUserId(userId, pageable)
            .map(this::convertToResponseDto);
    }
    
    public List<OrderResponseDto> getAllOrders() {
        return orderRepository.findAll().stream()
            .map(this::convertToResponseDto)
            .collect(Collectors.toList());
    }
    
    public OrderResponseDto updateOrderStatus(Long orderId, OrderStatus status) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));
        
        order.setStatus(status);
        Order updatedOrder = orderRepository.save(order);
        return convertToResponseDto(updatedOrder);
    }
    
    public void cancelOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));
        
        if (order.getStatus() != OrderStatus.PENDING && order.getStatus() != OrderStatus.CONFIRMED) {
            throw new BadRequestException("Cannot cancel order with status: " + order.getStatus());
        }
        
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);
    }
    
    public List<OrderResponseDto> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status).stream()
            .map(this::convertToResponseDto)
            .collect(Collectors.toList());
    }
    
    private OrderResponseDto convertToResponseDto(Order order) {
        OrderResponseDto dto = new OrderResponseDto();
        dto.setId(order.getId());
        dto.setUserId(order.getUserId());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setStatus(order.getStatus());
        dto.setShippingAddress(order.getShippingAddress());
        dto.setBillingAddress(order.getBillingAddress());
        dto.setCreatedAt(order.getCreatedAt());
        dto.setUpdatedAt(order.getUpdatedAt());
        
        if (order.getOrderItems() != null) {
            List<OrderItemResponseDto> itemDtos = order.getOrderItems().stream()
                .map(this::convertToOrderItemResponseDto)
                .collect(Collectors.toList());
            dto.setOrderItems(itemDtos);
        }
        
        return dto;
    }
    
    private OrderItemResponseDto convertToOrderItemResponseDto(OrderItem orderItem) {
        OrderItemResponseDto dto = new OrderItemResponseDto();
        dto.setId(orderItem.getId());
        dto.setProductId(orderItem.getProductId());
        dto.setProductName(orderItem.getProductName());
        dto.setQuantity(orderItem.getQuantity());
        dto.setUnitPrice(orderItem.getUnitPrice());
        dto.setTotalPrice(orderItem.getTotalPrice());
        return dto;
    }
}