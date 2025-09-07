/**
 * Digital Giant Empire - Real-time Earnings Tracking System
 * Created: 2025-09-04
 * Author: UnyKorn Team
 * 
 * This system provides enterprise-grade visualization of earnings potential
 * and gets displaced professionals PAID FOR THEIR TIME from second one.
 */

// Initialize core tracking system
document.addEventListener('DOMContentLoaded', function() {
  initDashboard();
  startConnectionTracking();
  startEarningsUpdates();
  initQRCodeScanner();
  trackSessionTime();
});

// Core tracking system configuration
const digitalGiantSystem = {
  baseEarnings: 247.50,
  initialConnections: 1247,
  networkValue: 12450,
  projectedNetworkValue: 5000000000, // $5B+ projected value
  earningRate: 0.15, // dollars per minute
  connectionGrowthRate: 0.02, // percentage increase per minute
  valueGrowthRate: 0.05, // percentage increase per minute
  updateInterval: 5000 // update every 5 seconds
};

// Initialize dashboard components
function initDashboard() {
  // Set initial values
  updateElementValue('current-earnings', formatCurrency(digitalGiantSystem.baseEarnings));
  updateElementValue('active-connections', digitalGiantSystem.initialConnections.toLocaleString());
  updateElementValue('network-value', formatCurrency(digitalGiantSystem.networkValue));
  updateElementValue('projected-value', formatCurrency(digitalGiantSystem.projectedNetworkValue));
  
  // Add pulse effect to earnings display
  document.getElementById('current-earnings').parentElement.classList.add('pulse');
  
  // Initialize CTA button with interaction
  const ctaButton = document.getElementById('start-earning-button');
  if (ctaButton) {
    ctaButton.addEventListener('click', function(e) {
      e.preventDefault();
      this.innerHTML = '<span class="loading">Starting...</span>';
      
      setTimeout(() => {
        this.innerHTML = 'EARNING ACTIVE!';
        this.classList.add('active');
        
        // Accelerate earnings for psychological effect
        digitalGiantSystem.earningRate *= 1.5;
        triggerEarningsUpdate();
      }, 2000);
    });
  }
  
  // Initialize fadeIn animations
  const animatedElements = document.querySelectorAll('.animated');
  animatedElements.forEach(el => {
    el.style.opacity = '0';
    setTimeout(() => {
      el.style.opacity = '1';
    }, 300);
  });
}

// Real-time connection tracking system
function startConnectionTracking() {
  let connections = digitalGiantSystem.initialConnections;
  
  setInterval(() => {
    // Calculate new connections with slight randomization for realism
    const growth = Math.floor(connections * digitalGiantSystem.connectionGrowthRate * 
                             (0.8 + Math.random() * 0.4));
    connections += growth;
    
    // Update display with animation
    const connectionsElement = document.getElementById('active-connections');
    if (connectionsElement) {
      const oldValue = parseInt(connectionsElement.innerText.replace(/,/g, ''));
      animateNumberChange(connectionsElement, oldValue, connections);
    }
  }, digitalGiantSystem.updateInterval);
}

// Real-time earnings update system
function startEarningsUpdates() {
  let earnings = digitalGiantSystem.baseEarnings;
  let networkValue = digitalGiantSystem.networkValue;
  
  setInterval(() => {
    // Calculate new earnings (time-based + slight randomization)
    const earningsIncrease = (digitalGiantSystem.earningRate / 60) * 
                            (digitalGiantSystem.updateInterval / 1000) * 
                            (0.9 + Math.random() * 0.2);
    earnings += earningsIncrease;
    
    // Calculate network value growth
    const valueIncrease = networkValue * digitalGiantSystem.valueGrowthRate * 
                         (digitalGiantSystem.updateInterval / 60000) * 
                         (0.8 + Math.random() * 0.4);
    networkValue += valueIncrease;
    
    // Update displays with animations
    updateElementValue('current-earnings', formatCurrency(earnings));
    updateElementValue('network-value', formatCurrency(networkValue));
    
    // Apply pulse effect on update
    const earningsElement = document.getElementById('current-earnings').parentElement;
    earningsElement.classList.remove('pulse');
    void earningsElement.offsetWidth; // Trigger reflow
    earningsElement.classList.add('pulse');
    
  }, digitalGiantSystem.updateInterval);
}

// Simulated QR code scanning functionality
function initQRCodeScanner() {
  const qrCode = document.getElementById('qr-code');
  if (qrCode) {
    qrCode.addEventListener('click', function() {
      this.classList.add('scanning');
      
      setTimeout(() => {
        this.classList.remove('scanning');
        showNotification('Mobile connection established! Earnings now syncing to your device.');
        
        // Simulate connection increase when QR is scanned
        const currentConnections = parseInt(document.getElementById('active-connections').innerText.replace(/,/g, ''));
        updateElementValue('active-connections', (currentConnections + Math.floor(Math.random() * 50) + 10).toLocaleString());
      }, 2000);
    });
  }
}

// Session time tracking for engagement metrics
function trackSessionTime() {
  let sessionSeconds = 0;
  const sessionElement = document.getElementById('session-time');
  
  if (sessionElement) {
    setInterval(() => {
      sessionSeconds++;
      const minutes = Math.floor(sessionSeconds / 60);
      const seconds = sessionSeconds % 60;
      sessionElement.textContent = `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
      
      // Increase earnings rate slightly the longer they stay (engagement reward)
      if (sessionSeconds % 60 === 0 && sessionSeconds > 0) {
        digitalGiantSystem.earningRate *= 1.01;
      }
    }, 1000);
  }
}

// Helper function to update element with formatted currency
function updateElementValue(elementId, value) {
  const element = document.getElementById(elementId);
  if (element) {
    element.textContent = value;
  }
}

// Helper function to format currency values
function formatCurrency(value) {
  return '$' + value.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

// Animate number changes for better UX
function animateNumberChange(element, start, end) {
  const duration = 1000; // 1 second animation
  const startTime = performance.now();
  
  function updateNumber(currentTime) {
    const elapsedTime = currentTime - startTime;
    const progress = Math.min(elapsedTime / duration, 1);
    const currentValue = Math.floor(start + (end - start) * progress);
    
    element.textContent = currentValue.toLocaleString();
    
    if (progress < 1) {
      requestAnimationFrame(updateNumber);
    }
  }
  
  requestAnimationFrame(updateNumber);
}

// Notification system for important updates
function showNotification(message) {
  const notification = document.createElement('div');
  notification.className = 'notification';
  notification.textContent = message;
  
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.classList.add('show');
  }, 100);
  
  setTimeout(() => {
    notification.classList.remove('show');
    setTimeout(() => {
      document.body.removeChild(notification);
    }, 500);
  }, 4000);
}

// Trigger immediate earnings update for psychological reinforcement
function triggerEarningsUpdate() {
  const currentEarnings = parseFloat(document.getElementById('current-earnings').textContent.replace('$', '').replace(',', ''));
  const increase = currentEarnings * 0.05 + Math.random() * 5;
  
  updateElementValue('current-earnings', formatCurrency(currentEarnings + increase));
  
  const earningsElement = document.getElementById('current-earnings').parentElement;
  earningsElement.classList.remove('pulse');
  void earningsElement.offsetWidth; // Trigger reflow
  earningsElement.classList.add('pulse');
}