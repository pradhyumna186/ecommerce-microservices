package com.ecommerce.user.security;

import com.ecommerce.user.entity.Role;
import com.ecommerce.user.entity.User;
import com.ecommerce.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component("userOwnership")
public class UserOwnershipEvaluator {
    
    @Autowired
    private UserService userService;
    
    /**
     * Checks if the current user can access the specified user resource.
     * Rules:
     * 1. Users can only access their own resources
     * 2. ADMIN users can access any user's resources
     * 
     * @param targetUserId The ID of the user resource to access
     * @return true if the current user is authorized to access the target user's resource
     */
    public boolean canAccessUser(Long targetUserId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }
        
        try {
            // Get the current user's email from the authentication context
            String currentUserEmail = authentication.getName();
            User currentUser = userService.getUserEntityByEmail(currentUserEmail);
            
            if (currentUser == null) {
                return false;
            }
            
            // ADMIN users can access any user's resources
            if (currentUser.getRole() == Role.ADMIN) {
                return true;
            }
            
            // Regular users can only access their own resources
            return currentUser.getId().equals(targetUserId);
            
        } catch (Exception e) {
            // If there's any error (e.g., user not found), deny access
            return false;
        }
    }
    
    /**
     * Checks if the current user is an admin
     * 
     * @return true if the current user has ADMIN role
     */
    public boolean isAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }
        
        try {
            String currentUserEmail = authentication.getName();
            User currentUser = userService.getUserEntityByEmail(currentUserEmail);
            return currentUser != null && currentUser.getRole() == Role.ADMIN;
        } catch (Exception e) {
            return false;
        }
    }
}
