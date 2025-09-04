// Unykorn Website JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initializeNavbar();
    initializeAnimations();
    initializeCounters();
    initializeCalculators();
    initializeInteractions();
    initializeScrollEffects();
    initializeWalletConnection();
    initializePackSelection();
    initializeCommissionCalculator();
});

// Navbar functionality
function initializeNavbar() {
    const navbar = document.querySelector('.navbar');
    const navLinks = document.querySelectorAll('.nav-link');
    
    // Navbar scroll effect
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = 'none';
        }
    });
    
    // Smooth scrolling for navigation links
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Animation effects
function initializeAnimations() {
    // Create intersection observer for fade-in animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe elements for animations
    const animatedElements = document.querySelectorAll('.layer-card, .tokenomics-card, .pack-card, .tier-card, .phase-card, .contract-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'all 0.6s ease-out';
        observer.observe(el);
    });
}

// Counter animations
function initializeCounters() {
    const counters = document.querySelectorAll('.stat-number');
    const observerOptions = {
        threshold: 0.5
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    counters.forEach(counter => {
        observer.observe(counter);
    });
}

function animateCounter(element) {
    const target = parseInt(element.dataset.target);
    const duration = 2000;
    const increment = target / (duration / 16);
    let current = 0;
    
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = formatNumber(target);
            clearInterval(timer);
        } else {
            element.textContent = formatNumber(Math.floor(current));
        }
    }, 16);
}

function formatNumber(num) {
    if (num >= 1000000000000) {
        return (num / 1000000000000).toFixed(0) + 'T';
    } else if (num >= 1000000000) {
        return (num / 1000000000).toFixed(0) + 'B';
    } else if (num >= 1000000) {
        return (num / 1000000).toFixed(0) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(0) + 'K';
    }
    return num.toString();
}

// Calculator functionality
function initializeCalculators() {
    // ROI Calculator
    const investmentInput = document.getElementById('investmentAmount');
    const targetPriceInput = document.getElementById('targetPrice');
    
    if (investmentInput && targetPriceInput) {
        const updateROI = () => {
            const investment = parseFloat(investmentInput.value) || 100;
            const targetPrice = parseFloat(targetPriceInput.value) || 0.10;
            const tokenPrice = 0.0001; // Initial token price
            
            const tokensReceived = (investment * 0.6) / tokenPrice; // 60% of investment goes to tokens
            const potentialValue = tokensReceived * targetPrice;
            const roi = ((potentialValue - investment) / investment * 100).toFixed(0);
            
            document.getElementById('tokensReceived').textContent = formatNumber(tokensReceived) + ' UNY';
            document.getElementById('potentialValue').textContent = '$' + formatNumber(potentialValue);
            document.getElementById('potentialROI').textContent = roi + 'x';
        };
        
        investmentInput.addEventListener('input', updateROI);
        targetPriceInput.addEventListener('input', updateROI);
        updateROI(); // Initial calculation
    }
}

// Interactive elements
function initializeInteractions() {
    // Layer card interactions
    const layerCards = document.querySelectorAll('.layer-card');
    layerCards.forEach((card, index) => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-10px) scale(1.02)';
            card.style.boxShadow = '0 25px 50px -12px rgba(0, 0, 0, 0.25)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
            card.style.boxShadow = '0 10px 15px -3px rgba(0, 0, 0, 0.1)';
        });
    });
    
    // Pack card selection
    const packCards = document.querySelectorAll('.pack-card');
    packCards.forEach(card => {
        card.addEventListener('click', () => {
            packCards.forEach(c => c.classList.remove('selected'));
            card.classList.add('selected');
            
            // Add selection styles
            card.style.borderColor = 'var(--primary-color)';
            card.style.boxShadow = '0 0 0 3px rgba(99, 102, 241, 0.1)';
        });
    });
    
    // Smooth hover effects for buttons
    const buttons = document.querySelectorAll('.btn-primary, .btn-secondary, .pack-cta');
    buttons.forEach(button => {
        button.addEventListener('mouseenter', () => {
            button.style.transform = 'translateY(-2px)';
        });
        
        button.addEventListener('mouseleave', () => {
            button.style.transform = 'translateY(0)';
        });
    });
}

// Scroll effects
function initializeScrollEffects() {
    // Parallax effect for hero background
    const heroBackground = document.querySelector('.hero-background');
    const floatingShapes = document.querySelectorAll('.shape');
    
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const rate = scrolled * -0.5;
        
        if (heroBackground) {
            heroBackground.style.transform = `translateY(${rate}px)`;
        }
        
        // Floating shapes parallax
        floatingShapes.forEach((shape, index) => {
            const rate = scrolled * (-0.2 - index * 0.1);
            shape.style.transform = `translateY(${rate}px)`;
        });
    });
    
    // Progress indicator (could be added to show scroll progress)
    const progressBar = document.createElement('div');
    progressBar.style.position = 'fixed';
    progressBar.style.top = '0';
    progressBar.style.left = '0';
    progressBar.style.width = '0%';
    progressBar.style.height = '3px';
    progressBar.style.background = 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)';
    progressBar.style.zIndex = '9999';
    progressBar.style.transition = 'width 0.1s ease';
    document.body.appendChild(progressBar);
    
    window.addEventListener('scroll', () => {
        const scrollTop = window.pageYOffset;
        const docHeight = document.body.scrollHeight - window.innerHeight;
        const scrollPercent = (scrollTop / docHeight) * 100;
        progressBar.style.width = scrollPercent + '%';
    });
}

// Wallet connection
function initializeWalletConnection() {
    const connectWalletBtn = document.getElementById('connectWallet');
    
    if (connectWalletBtn) {
        connectWalletBtn.addEventListener('click', async () => {
            try {
                if (typeof window.ethereum !== 'undefined') {
                    // Request account access
                    const accounts = await window.ethereum.request({
                        method: 'eth_requestAccounts'
                    });
                    
                    if (accounts.length > 0) {
                        const account = accounts[0];
                        const shortAccount = account.slice(0, 6) + '...' + account.slice(-4);
                        connectWalletBtn.textContent = shortAccount;
                        connectWalletBtn.style.background = 'var(--success-color)';
                        
                        // Show success notification
                        showNotification('Wallet connected successfully!', 'success');
                        
                        // Update UI to show wallet connected state
                        updateWalletState(account);
                    }
                } else {
                    showNotification('Please install MetaMask to connect your wallet', 'warning');
                }
            } catch (error) {
                console.error('Error connecting wallet:', error);
                showNotification('Failed to connect wallet. Please try again.', 'error');
            }
        });
    }
}

// Pack selection functionality
function initializePackSelection() {
    const packCards = document.querySelectorAll('.pack-card');
    const packButtons = document.querySelectorAll('.pack-cta');
    
    packButtons.forEach((button, index) => {
        button.addEventListener('click', () => {
            const packTypes = ['starter', 'growth', 'pro'];
            const packType = packTypes[index];
            const prices = [25, 50, 100];
            const price = prices[index];
            
            // Show purchase modal or redirect to purchase flow
            showPurchaseModal(packType, price);
        });
    });
}

// Commission calculator
function initializeCommissionCalculator() {
    const roleSelect = document.getElementById('calculatorRole');
    const packSelect = document.getElementById('calculatorPack');
    const referralsInput = document.getElementById('calculatorReferrals');
    const teamSizeInput = document.getElementById('calculatorTeam');
    
    if (roleSelect && packSelect && referralsInput && teamSizeInput) {
        const updateCalculation = () => {
            const role = roleSelect.value;
            const packValue = parseInt(packSelect.value);
            const referrals = parseInt(referralsInput.value) || 0;
            const teamSize = parseInt(teamSizeInput.value) || 0;
            
            let directRate = 0.12; // Default advocate rate
            let hasTeamOverride = false;
            let hasFoundingBonus = false;
            
            switch (role) {
                case 'advocate':
                    directRate = 0.12;
                    break;
                case 'hustler':
                    directRate = 0.50;
                    hasTeamOverride = true;
                    break;
                case 'founding':
                    directRate = 0.50;
                    hasTeamOverride = true;
                    hasFoundingBonus = true;
                    break;
            }
            
            const directCommission = packValue * directRate * referrals;
            const teamOverride = hasTeamOverride ? (packValue * 0.02 * teamSize) : 0;
            const foundingBonus = hasFoundingBonus ? (packValue * 0.05 * referrals) : 0;
            const totalMonthly = directCommission + teamOverride + foundingBonus;
            
            // Update display
            document.getElementById('directCommission').textContent = '$' + Math.round(directCommission);
            document.getElementById('teamOverride').textContent = '$' + Math.round(teamOverride);
            document.getElementById('foundingBonus').textContent = '$' + Math.round(foundingBonus);
            document.getElementById('totalMonthly').textContent = '$' + Math.round(totalMonthly);
            
            // Annual projections
            document.getElementById('conservativeAnnual').textContent = '$' + Math.round(totalMonthly * 6);
            document.getElementById('realisticAnnual').textContent = '$' + Math.round(totalMonthly * 12);
            document.getElementById('aggressiveAnnual').textContent = '$' + Math.round(totalMonthly * 24);
        };
        
        roleSelect.addEventListener('change', updateCalculation);
        packSelect.addEventListener('change', updateCalculation);
        referralsInput.addEventListener('input', updateCalculation);
        teamSizeInput.addEventListener('input', updateCalculation);
        
        updateCalculation(); // Initial calculation
    }
}

// Utility functions
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 8px;
        color: white;
        font-weight: 600;
        z-index: 10000;
        transform: translateX(400px);
        transition: transform 0.3s ease;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    `;
    
    // Set background color based on type
    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f59e0b',
        info: '#3b82f6'
    };
    notification.style.background = colors[type] || colors.info;
    
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after delay
    setTimeout(() => {
        notification.style.transform = 'translateX(400px)';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

function showPurchaseModal(packType, price) {
    // Create modal
    const modal = document.createElement('div');
    modal.className = 'purchase-modal';
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.8);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
        opacity: 0;
        transition: opacity 0.3s ease;
    `;
    
    const modalContent = document.createElement('div');
    modalContent.className = 'modal-content';
    modalContent.style.cssText = `
        background: white;
        border-radius: 16px;
        padding: 40px;
        max-width: 500px;
        width: 90%;
        text-align: center;
        transform: scale(0.9);
        transition: transform 0.3s ease;
    `;
    
    modalContent.innerHTML = `
        <div style="font-size: 3rem; margin-bottom: 20px;">
            ${packType === 'starter' ? '🌱' : packType === 'growth' ? '🚀' : '💎'}
        </div>
        <h3 style="font-size: 2rem; margin-bottom: 10px; color: #1e293b;">
            ${packType.charAt(0).toUpperCase() + packType.slice(1)} Pack
        </h3>
        <p style="font-size: 3rem; font-weight: 800; background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 20px;">
            $${price}
        </p>
        <p style="color: #64748b; margin-bottom: 30px; line-height: 1.6;">
            Ready to join the Unykorn ecosystem? This pack includes tokens, asset vault allocation, and commission earning potential.
        </p>
        <div style="display: flex; gap: 15px; justify-content: center;">
            <button id="confirmPurchase" style="background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; border: none; padding: 15px 30px; border-radius: 12px; font-weight: 600; cursor: pointer;">
                Purchase Now
            </button>
            <button id="cancelPurchase" style="background: #f1f5f9; color: #64748b; border: none; padding: 15px 30px; border-radius: 12px; font-weight: 600; cursor: pointer;">
                Cancel
            </button>
        </div>
    `;
    
    modal.appendChild(modalContent);
    document.body.appendChild(modal);
    
    // Animate in
    setTimeout(() => {
        modal.style.opacity = '1';
        modalContent.style.transform = 'scale(1)';
    }, 100);
    
    // Event listeners
    document.getElementById('confirmPurchase').addEventListener('click', () => {
        // Here you would integrate with the smart contract
        showNotification(`${packType} pack purchase initiated!`, 'info');
        closeModal();
    });
    
    document.getElementById('cancelPurchase').addEventListener('click', closeModal);
    modal.addEventListener('click', (e) => {
        if (e.target === modal) closeModal();
    });
    
    function closeModal() {
        modal.style.opacity = '0';
        modalContent.style.transform = 'scale(0.9)';
        setTimeout(() => {
            document.body.removeChild(modal);
        }, 300);
    }
}

function updateWalletState(account) {
    // Update any wallet-dependent UI elements
    const walletElements = document.querySelectorAll('.wallet-dependent');
    walletElements.forEach(el => {
        el.style.display = 'block';
    });
    
    // Store wallet state
    localStorage.setItem('connectedWallet', account);
    
    // Check if user has any tokens or positions
    // This would integrate with the smart contracts to fetch user data
    updateUserStats(account);
}

async function updateUserStats(account) {
    // This would fetch real data from the smart contracts
    const mockStats = {
        tokens: '125,000 UNY',
        vaultShares: '$450',
        commissions: '$1,250',
        pocStreak: '7 days'
    };
    
    // Update any stats displays on the page
    const statsElements = {
        'user-tokens': mockStats.tokens,
        'user-vault': mockStats.vaultShares,
        'user-commissions': mockStats.commissions,
        'user-streak': mockStats.pocStreak
    };
    
    Object.entries(statsElements).forEach(([id, value]) => {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    });
}

// Auto-update dynamic content
setInterval(() => {
    // Update circulating supply (mock data - would come from smart contract)
    const circulatingElement = document.getElementById('circulatingSupply');
    if (circulatingElement) {
        const currentSupply = 999850000000; // Mock decreasing supply
        circulatingElement.textContent = formatNumber(currentSupply) + ' UNY';
    }
    
    // Update total burned (mock data)
    const burnedElement = document.getElementById('totalBurned');
    if (burnedElement) {
        const totalBurned = 150000000; // Mock burned amount
        burnedElement.textContent = formatNumber(totalBurned) + ' UNY';
    }
}, 5000);

// Initialize demo mode if no wallet is connected
document.addEventListener('DOMContentLoaded', () => {
    // Check if wallet was previously connected
    const connectedWallet = localStorage.getItem('connectedWallet');
    if (connectedWallet) {
        const connectBtn = document.getElementById('connectWallet');
        if (connectBtn) {
            const shortAccount = connectedWallet.slice(0, 6) + '...' + connectedWallet.slice(-4);
            connectBtn.textContent = shortAccount;
            connectBtn.style.background = 'var(--success-color)';
            updateWalletState(connectedWallet);
        }
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
    // Alt + H to scroll to hero
    if (e.altKey && e.key === 'h') {
        document.getElementById('hero').scrollIntoView({ behavior: 'smooth' });
    }
    
    // Alt + E to scroll to ecosystem
    if (e.altKey && e.key === 'e') {
        document.getElementById('ecosystem').scrollIntoView({ behavior: 'smooth' });
    }
    
    // Alt + T to scroll to tokenomics
    if (e.altKey && e.key === 't') {
        document.getElementById('tokenomics').scrollIntoView({ behavior: 'smooth' });
    }
    
    // Escape to close any modals
    if (e.key === 'Escape') {
        const modals = document.querySelectorAll('.purchase-modal');
        modals.forEach(modal => {
            if (modal.style.opacity !== '0') {
                modal.click(); // Trigger close
            }
        });
    }
});