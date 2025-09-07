// Digital Giant - Connection Economy Revolution JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initializeNavigation();
    initializeAnimations();
    initializeCounters();
    initializeScrollEffects();
    initializeInteractions();
    
    console.log('🏗️ Digital Giant - Connection Economy Revolution Initialized');
});

// Navigation functionality
function initializeNavigation() {
    const navbar = document.querySelector('.navbar');
    const navLinks = document.querySelectorAll('.nav-link');
    
    // Navbar scroll effect
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = 'none';
        }
    });
    
    // Smooth scroll for navigation links
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const navHeight = navbar.offsetHeight;
                const targetPosition = targetSection.offsetTop - navHeight;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
                
                // Update active nav link
                navLinks.forEach(l => l.classList.remove('active'));
                link.classList.add('active');
            }
        });
    });
}

// Animation and visual effects
function initializeAnimations() {
    // Animated counters for hero stats
    const statNumbers = document.querySelectorAll('.stat-number');
    
    statNumbers.forEach(stat => {
        const target = parseInt(stat.getAttribute('data-target'));
        animateCounter(stat, target);
    });
    
    // Network node animations
    const networkNodes = document.querySelectorAll('.network-node:not(.central)');
    
    networkNodes.forEach((node, index) => {
        node.style.animationDelay = `${index * 0.5}s`;
        node.addEventListener('mouseenter', () => {
            node.style.transform = 'scale(1.2)';
            node.style.boxShadow = '0 0 20px rgba(255, 215, 0, 0.5)';
        });
        
        node.addEventListener('mouseleave', () => {
            node.style.transform = 'scale(1)';
            node.style.boxShadow = 'none';
        });
    });
    
    // Connection line animations
    const connectionLines = document.querySelectorAll('.connection-line');
    connectionLines.forEach((line, index) => {
        line.style.animationDelay = `${index * 0.7}s`;
    });
}

// Counter animation function
function animateCounter(element, target) {
    let current = 0;
    const increment = target / 100;
    const duration = 2000; // 2 seconds
    const stepTime = duration / 100;
    
    const timer = setInterval(() => {
        current += increment;
        
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }
        
        // Format large numbers
        if (target >= 1000000) {
            element.textContent = (current / 1000000).toFixed(1) + 'M';
        } else if (target >= 1000) {
            element.textContent = (current / 1000).toFixed(0) + 'K';
        } else {
            element.textContent = Math.floor(current);
        }
    }, stepTime);
}

// Scroll-based animations
function initializeScrollEffects() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                
                // Trigger specific animations for different elements
                if (entry.target.classList.contains('infra-card')) {
                    animateInfraCard(entry.target);
                }
                
                if (entry.target.classList.contains('vision-card')) {
                    animateVisionCard(entry.target);
                }
                
                if (entry.target.classList.contains('step-card')) {
                    animateStepCard(entry.target);
                }
            }
        });
    }, observerOptions);
    
    // Observe elements for scroll animations
    const scrollElements = document.querySelectorAll(`
        .vision-card, 
        .infra-card, 
        .stream-card, 
        .case-card, 
        .step-card,
        .phase,
        .security-card,
        .community-card
    `);
    
    scrollElements.forEach(el => {
        el.classList.add('scroll-reveal');
        observer.observe(el);
    });
}

// Card-specific animations
function animateInfraCard(card) {
    const delay = Array.from(card.parentNode.children).indexOf(card) * 100;
    
    setTimeout(() => {
        card.style.transform = 'translateY(0)';
        card.style.opacity = '1';
        
        // Animate value highlight
        const valueElement = card.querySelector('.card-value');
        if (valueElement) {
            valueElement.style.animation = 'pulse 0.5s ease-in-out';
        }
    }, delay);
}

function animateVisionCard(card) {
    const delay = Array.from(card.parentNode.children).indexOf(card) * 200;
    
    setTimeout(() => {
        card.style.transform = 'translateY(0) scale(1)';
        card.style.opacity = '1';
        
        // Animate icon
        const icon = card.querySelector('.card-icon');
        if (icon) {
            icon.style.animation = 'bounce 0.6s ease-in-out';
        }
    }, delay);
}

function animateStepCard(card) {
    const delay = Array.from(card.parentNode.children).indexOf(card) * 150;
    
    setTimeout(() => {
        card.style.transform = 'translateY(0)';
        card.style.opacity = '1';
        
        // Animate step number
        const number = card.querySelector('.step-number');
        if (number) {
            number.style.animation = 'zoomIn 0.5s ease-in-out';
        }
    }, delay);
}

// Interactive features
function initializeInteractions() {
    // Button interactions
    const buttons = document.querySelectorAll('button, .btn-primary, .btn-secondary, .btn-outline');
    
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            // Create ripple effect
            createRippleEffect(e, this);
            
            // Handle specific button actions
            handleButtonAction(this);
        });
    });
    
    // Card hover effects
    const cards = document.querySelectorAll(`
        .vision-card, 
        .infra-card, 
        .stream-card, 
        .case-card,
        .security-card,
        .community-card
    `);
    
    cards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-10px) scale(1.02)';
            card.style.boxShadow = '0 20px 60px rgba(0, 0, 0, 0.15)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
            card.style.boxShadow = '0 10px 40px rgba(0, 0, 0, 0.1)';
        });
    });
    
    // Phase status interactions
    const phases = document.querySelectorAll('.phase');
    phases.forEach(phase => {
        phase.addEventListener('click', () => {
            expandPhaseDetails(phase);
        });
    });
    
    // Community links with tracking
    const communityLinks = document.querySelectorAll('.community-card');
    communityLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            const platform = link.querySelector('h3').textContent;
            trackEvent('community_link_click', { platform });
        });
    });
}

// Ripple effect for buttons
function createRippleEffect(event, element) {
    const circle = document.createElement('span');
    const diameter = Math.max(element.clientWidth, element.clientHeight);
    const radius = diameter / 2;
    
    const rect = element.getBoundingClientRect();
    const left = event.clientX - rect.left - radius;
    const top = event.clientY - rect.top - radius;
    
    circle.style.width = circle.style.height = `${diameter}px`;
    circle.style.left = `${left}px`;
    circle.style.top = `${top}px`;
    circle.style.position = 'absolute';
    circle.style.borderRadius = '50%';
    circle.style.background = 'rgba(255, 255, 255, 0.3)';
    circle.style.transform = 'scale(0)';
    circle.style.animation = 'ripple 0.6s linear';
    circle.style.pointerEvents = 'none';
    
    element.style.position = 'relative';
    element.style.overflow = 'hidden';
    element.appendChild(circle);
    
    setTimeout(() => {
        circle.remove();
    }, 600);
}

// Handle button actions
function handleButtonAction(button) {
    const buttonText = button.textContent.trim();
    
    switch (buttonText) {
        case 'Get Started':
        case 'Join The Revolution':
            handleGetStarted();
            break;
        case 'Watch Demo':
            handleWatchDemo();
            break;
        case 'Join Community':
            handleJoinCommunity();
            break;
        case 'Read Docs':
            handleReadDocs();
            break;
        default:
            console.log(`Button clicked: ${buttonText}`);
    }
}

// Action handlers
function handleGetStarted() {
    trackEvent('get_started_click');
    
    // Create modal or redirect to onboarding
    showModal('Get Started', `
        <div class="onboarding-modal">
            <h3>🏗️ Join the Digital Giant Revolution!</h3>
            <p>Choose your path to start building your digital empire:</p>
            
            <div class="onboarding-options">
                <div class="option-card">
                    <div class="option-icon">📱</div>
                    <h4>Quick Start</h4>
                    <p>Scan QR code or text "START" to join</p>
                    <button class="btn-primary">Start Now</button>
                </div>
                
                <div class="option-card">
                    <div class="option-icon">👥</div>
                    <h4>Community First</h4>
                    <p>Join our Discord and meet other connection masters</p>
                    <button class="btn-secondary">Join Discord</button>
                </div>
                
                <div class="option-card">
                    <div class="option-icon">📚</div>
                    <h4>Learn More</h4>
                    <p>Read our documentation and technical details</p>
                    <button class="btn-outline">View Docs</button>
                </div>
            </div>
        </div>
    `);
}

function handleWatchDemo() {
    trackEvent('watch_demo_click');
    
    showModal('Demo Video', `
        <div class="demo-modal">
            <h3>🎥 Digital Giant Platform Demo</h3>
            <div class="video-placeholder">
                <div class="video-icon">🎬</div>
                <p>Interactive demo coming soon!</p>
                <p>See how connection masters are building wealth through our platform:</p>
                
                <div class="demo-features">
                    <div class="demo-feature">✅ QR Code onboarding in seconds</div>
                    <div class="demo-feature">✅ POC beacon check-ins for rewards</div>
                    <div class="demo-feature">✅ Commission tracking dashboard</div>
                    <div class="demo-feature">✅ Real-time asset vault monitoring</div>
                </div>
                
                <button class="btn-primary">Request Early Access</button>
            </div>
        </div>
    `);
}

function handleJoinCommunity() {
    trackEvent('join_community_click');
    
    // Open Discord in new tab
    window.open('https://discord.gg/digitalgiant', '_blank');
}

function handleReadDocs() {
    trackEvent('read_docs_click');
    
    // Open docs in new tab (when available)
    window.open('https://docs.digitalgiant.com', '_blank');
}

// Modal system
function showModal(title, content) {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h2>${title}</h2>
                <button class="modal-close">&times;</button>
            </div>
            <div class="modal-body">
                ${content}
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    document.body.style.overflow = 'hidden';
    
    // Close modal functionality
    const closeBtn = modal.querySelector('.modal-close');
    closeBtn.addEventListener('click', () => closeModal(modal));
    
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModal(modal);
        }
    });
    
    // Animate modal in
    setTimeout(() => {
        modal.classList.add('modal-active');
    }, 10);
}

function closeModal(modal) {
    modal.classList.remove('modal-active');
    document.body.style.overflow = 'auto';
    
    setTimeout(() => {
        modal.remove();
    }, 300);
}

// Phase expansion
function expandPhaseDetails(phase) {
    const isExpanded = phase.classList.contains('expanded');
    
    // Close other expanded phases
    document.querySelectorAll('.phase.expanded').forEach(p => {
        if (p !== phase) {
            p.classList.remove('expanded');
        }
    });
    
    if (!isExpanded) {
        phase.classList.add('expanded');
        
        // Add detailed information
        if (!phase.querySelector('.phase-details')) {
            const details = document.createElement('div');
            details.className = 'phase-details';
            details.innerHTML = generatePhaseDetails(phase);
            phase.appendChild(details);
        }
    } else {
        phase.classList.remove('expanded');
    }
}

function generatePhaseDetails(phase) {
    const phaseNumber = phase.querySelector('.phase-number').textContent;
    
    const details = {
        '1': {
            budget: '$250K',
            timeline: '90 days',
            team: '15 people',
            focus: 'Foundation & Security'
        },
        '2': {
            budget: '$500K',
            timeline: '180 days',
            team: '25 people',
            focus: 'Growth & Partnerships'
        },
        '3': {
            budget: '$1M',
            timeline: '270 days',
            team: '50 people',
            focus: 'Scale & International'
        }
    };
    
    const detail = details[phaseNumber] || details['1'];
    
    return `
        <div class="phase-detail-grid">
            <div class="detail-item">
                <div class="detail-label">Budget</div>
                <div class="detail-value">${detail.budget}</div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Timeline</div>
                <div class="detail-value">${detail.timeline}</div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Team Size</div>
                <div class="detail-value">${detail.team}</div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Focus Area</div>
                <div class="detail-value">${detail.focus}</div>
            </div>
        </div>
    `;
}

// Analytics and tracking
function trackEvent(eventName, properties = {}) {
    // Basic event tracking (replace with your analytics service)
    console.log(`📊 Event: ${eventName}`, properties);
    
    // Example: Send to analytics service
    // analytics.track(eventName, properties);
}

// Initialize counters when they come into view
function initializeCounters() {
    const counterObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const counter = entry.target;
                const target = parseInt(counter.getAttribute('data-target'));
                animateCounter(counter, target);
                counterObserver.unobserve(counter);
            }
        });
    }, { threshold: 0.5 });
    
    document.querySelectorAll('.stat-number[data-target]').forEach(counter => {
        counterObserver.observe(counter);
    });
}

// Add custom CSS for modal system
const modalStyles = `
<style>
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    z-index: 10000;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
}

.modal-overlay.modal-active {
    opacity: 1;
    visibility: visible;
}

.modal-content {
    background: white;
    border-radius: 16px;
    max-width: 600px;
    max-height: 80vh;
    overflow-y: auto;
    transform: scale(0.9) translateY(20px);
    transition: all 0.3s ease;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-overlay.modal-active .modal-content {
    transform: scale(1) translateY(0);
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 2rem 2rem 1rem;
    border-bottom: 1px solid var(--border);
}

.modal-header h2 {
    margin: 0;
    color: var(--primary);
    font-weight: var(--font-weight-bold);
}

.modal-close {
    background: none;
    border: none;
    font-size: 2rem;
    cursor: pointer;
    color: var(--text-secondary);
    padding: 0;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.3s ease;
}

.modal-close:hover {
    background: var(--surface);
    color: var(--primary);
}

.modal-body {
    padding: 1rem 2rem 2rem;
}

.onboarding-options {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
}

.option-card {
    text-align: center;
    padding: 1.5rem;
    background: var(--surface);
    border-radius: 12px;
    transition: transform 0.3s ease;
}

.option-card:hover {
    transform: translateY(-5px);
}

.option-icon {
    font-size: 2rem;
    margin-bottom: 1rem;
}

.option-card h4 {
    margin-bottom: 0.5rem;
    color: var(--primary);
}

.option-card p {
    font-size: 0.9rem;
    color: var(--text-secondary);
    margin-bottom: 1rem;
}

.demo-features {
    margin: 1rem 0;
    text-align: left;
}

.demo-feature {
    padding: 0.5rem 0;
    color: var(--success);
    font-weight: var(--font-weight-medium);
}

.video-placeholder {
    text-align: center;
    padding: 2rem;
    background: var(--surface);
    border-radius: 12px;
}

.video-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.5;
}

.phase.expanded {
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    border-left: 4px solid var(--primary);
}

.phase-details {
    margin-top: 2rem;
    padding-top: 2rem;
    border-top: 1px solid var(--border);
    animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.phase-detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 1rem;
}

.detail-item {
    text-align: center;
    padding: 1rem;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.detail-label {
    font-size: 0.8rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 0.5rem;
}

.detail-value {
    font-size: 1.1rem;
    font-weight: var(--font-weight-bold);
    color: var(--primary);
}

@keyframes ripple {
    to {
        transform: scale(4);
        opacity: 0;
    }
}

@keyframes bounce {
    0%, 20%, 53%, 80%, 100% {
        transform: translate3d(0, 0, 0);
    }
    40%, 43% {
        transform: translate3d(0, -10px, 0);
    }
    70% {
        transform: translate3d(0, -5px, 0);
    }
    90% {
        transform: translate3d(0, -2px, 0);
    }
}

@keyframes zoomIn {
    from {
        opacity: 0;
        transform: scale3d(0.3, 0.3, 0.3);
    }
    50% {
        opacity: 1;
    }
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .modal-content {
        margin: 1rem;
        max-height: 90vh;
    }
    
    .onboarding-options {
        grid-template-columns: 1fr;
    }
    
    .phase-detail-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}
</style>
`;

// Inject modal styles into document
document.head.insertAdjacentHTML('beforeend', modalStyles);

// Performance monitoring
const performanceObserver = new PerformanceObserver((list) => {
    list.getEntries().forEach((entry) => {
        if (entry.entryType === 'navigation') {
            console.log(`📈 Page Load Time: ${entry.loadEventEnd - entry.loadEventStart}ms`);
        }
    });
});

if ('PerformanceObserver' in window) {
    performanceObserver.observe({ entryTypes: ['navigation'] });
}

// Service worker registration for offline functionality
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then((registration) => {
                console.log('🔧 SW registered: ', registration);
            })
            .catch((registrationError) => {
                console.log('🔧 SW registration failed: ', registrationError);
            });
    });
}