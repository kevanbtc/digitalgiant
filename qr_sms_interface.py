#!/usr/bin/env python3
"""
📱 QR Code & SMS Interface System
User-friendly onboarding with accessibility features
"""

import qrcode
import qrcode.image.svg
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import asyncio
import aiohttp
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import logging
from dataclasses import dataclass
import hashlib
import secrets
import re
from web3 import Web3
from eth_account import Account

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class AccessibilityOptions:
    high_contrast: bool = False
    large_text: bool = False
    audio_description: bool = False
    simple_language: bool = False
    font_size: int = 12
    contrast_ratio: str = "normal"  # "normal", "high", "maximum"

@dataclass
class QRConfiguration:
    size: int = 300
    border: int = 4
    error_correction: str = "M"  # L, M, Q, H
    fill_color: str = "black"
    back_color: str = "white"
    accessibility: AccessibilityOptions = None

@dataclass
class SMSTemplate:
    template_id: str
    message: str
    max_length: int = 160
    language: str = "en"
    accessibility_friendly: bool = False

class QRCodeGenerator:
    def __init__(self):
        self.default_config = QRConfiguration()
        
    def create_referral_qr(
        self,
        referrer_address: str,
        referral_code: str,
        config: Optional[QRConfiguration] = None
    ) -> Tuple[str, bytes]:
        """Generate QR code for referral with accessibility options"""
        
        if config is None:
            config = self.default_config
            
        # Create referral URL
        base_url = "https://unykorn.com/join"
        qr_data = f"{base_url}?ref={referral_code}&addr={referrer_address}"
        
        # Configure QR code based on accessibility needs
        error_correct_map = {
            "L": qrcode.constants.ERROR_CORRECT_L,
            "M": qrcode.constants.ERROR_CORRECT_M,
            "Q": qrcode.constants.ERROR_CORRECT_Q,
            "H": qrcode.constants.ERROR_CORRECT_H
        }
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=error_correct_map.get(config.error_correction, qrcode.constants.ERROR_CORRECT_M),
            box_size=10,
            border=config.border,
        )
        
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        # Apply accessibility modifications
        if config.accessibility and config.accessibility.high_contrast:
            fill_color = "#000000"
            back_color = "#FFFFFF"
        else:
            fill_color = config.fill_color
            back_color = config.back_color
            
        # Create image
        img = qr.make_image(fill_color=fill_color, back_color=back_color)
        img = img.resize((config.size, config.size), Image.NEAREST)
        
        # Add accessibility features
        if config.accessibility:
            img = self._add_accessibility_features(img, config.accessibility, referral_code)
        
        # Convert to bytes
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_bytes = img_buffer.getvalue()
        
        return qr_data, img_bytes
    
    def create_pack_sale_qr(
        self,
        pack_type: str,
        price_usd: int,
        seller_address: str,
        config: Optional[QRConfiguration] = None
    ) -> Tuple[str, bytes]:
        """Generate QR code for pack sales"""
        
        if config is None:
            config = self.default_config
            
        base_url = "https://unykorn.com/buy"
        qr_data = f"{base_url}?pack={pack_type}&price={price_usd}&seller={seller_address}"
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=config.border,
        )
        
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color=config.fill_color, back_color=config.back_color)
        img = img.resize((config.size, config.size), Image.NEAREST)
        
        # Add pack information overlay for accessibility
        if config.accessibility and config.accessibility.large_text:
            img = self._add_pack_info_overlay(img, pack_type, price_usd)
        
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_bytes = img_buffer.getvalue()
        
        return qr_data, img_bytes
    
    def create_poc_beacon_qr(
        self,
        beacon_id: str,
        latitude: float,
        longitude: float,
        location_name: str,
        config: Optional[QRConfiguration] = None
    ) -> Tuple[str, bytes]:
        """Generate QR code for POC (Proof of Contact) beacons"""
        
        if config is None:
            config = self.default_config
            
        base_url = "https://unykorn.com/checkin"
        qr_data = f"{base_url}?beacon={beacon_id}&lat={latitude}&lng={longitude}&loc={location_name}"
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction for outdoor use
            box_size=12,
            border=config.border,
        )
        
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color=config.fill_color, back_color=config.back_color)
        img = img.resize((config.size, config.size), Image.NEAREST)
        
        # Add location information for accessibility
        if config.accessibility:
            img = self._add_location_overlay(img, location_name, beacon_id)
        
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_bytes = img_buffer.getvalue()
        
        return qr_data, img_bytes
    
    def _add_accessibility_features(
        self, 
        img: Image.Image, 
        accessibility: AccessibilityOptions,
        referral_code: str
    ) -> Image.Image:
        """Add accessibility features to QR code"""
        
        # Create a larger canvas for additional information
        canvas_height = img.height + (100 if accessibility.large_text else 50)
        canvas = Image.new('RGB', (img.width, canvas_height), accessibility.back_color if hasattr(accessibility, 'back_color') else 'white')
        
        # Paste QR code
        canvas.paste(img, (0, 0))
        
        # Add text information
        draw = ImageDraw.Draw(canvas)
        
        try:
            font_size = accessibility.font_size if accessibility.large_text else 12
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
        
        # Add referral code text
        text = f"Referral Code: {referral_code}"
        if accessibility.simple_language:
            text = f"Your Code: {referral_code}"
            
        text_color = "black" if accessibility.high_contrast else "gray"
        text_pos = (10, img.height + 10)
        draw.text(text_pos, text, fill=text_color, font=font)
        
        # Add instructions
        instruction_text = "Scan with camera or enter code manually"
        if accessibility.simple_language:
            instruction_text = "Point camera here or type code above"
            
        instruction_pos = (10, img.height + 30)
        draw.text(instruction_pos, instruction_text, fill=text_color, font=font)
        
        return canvas
    
    def _add_pack_info_overlay(
        self, 
        img: Image.Image, 
        pack_type: str, 
        price_usd: int
    ) -> Image.Image:
        """Add pack information overlay"""
        
        canvas_height = img.height + 80
        canvas = Image.new('RGB', (img.width, canvas_height), 'white')
        canvas.paste(img, (0, 0))
        
        draw = ImageDraw.Draw(canvas)
        
        try:
            font = ImageFont.truetype("arial.ttf", 14)
        except:
            font = ImageFont.load_default()
        
        pack_text = f"{pack_type.upper()} PACK - ${price_usd}"
        text_pos = (10, img.height + 10)
        draw.text(text_pos, pack_text, fill="black", font=font)
        
        instruction_text = "Scan to purchase instantly"
        instruction_pos = (10, img.height + 35)
        draw.text(instruction_pos, instruction_text, fill="gray", font=font)
        
        return canvas
    
    def _add_location_overlay(
        self, 
        img: Image.Image, 
        location_name: str, 
        beacon_id: str
    ) -> Image.Image:
        """Add location information overlay"""
        
        canvas_height = img.height + 100
        canvas = Image.new('RGB', (img.width, canvas_height), 'white')
        canvas.paste(img, (0, 0))
        
        draw = ImageDraw.Draw(canvas)
        
        try:
            font = ImageFont.truetype("arial.ttf", 12)
            title_font = ImageFont.truetype("arial.ttf", 16)
        except:
            font = ImageFont.load_default()
            title_font = ImageFont.load_default()
        
        title_text = location_name.upper()
        title_pos = (10, img.height + 10)
        draw.text(title_pos, title_text, fill="black", font=title_font)
        
        beacon_text = f"Beacon ID: {beacon_id}"
        beacon_pos = (10, img.height + 35)
        draw.text(beacon_pos, beacon_text, fill="gray", font=font)
        
        instruction_text = "Scan to check in and earn rewards"
        instruction_pos = (10, img.height + 55)
        draw.text(instruction_pos, instruction_text, fill="gray", font=font)
        
        return canvas

class SMSOnboardingSystem:
    def __init__(self, sms_provider_config: Dict[str, str]):
        self.sms_config = sms_provider_config
        self.templates = self._initialize_templates()
        self.verification_codes = {}
        
    def _initialize_templates(self) -> Dict[str, SMSTemplate]:
        """Initialize SMS templates for different languages and accessibility needs"""
        templates = {
            "welcome_en": SMSTemplate(
                template_id="welcome_en",
                message="Welcome to Unykorn! Your verification code is: {code}. Enter this code to complete registration. Reply STOP to opt out.",
                language="en"
            ),
            "welcome_simple": SMSTemplate(
                template_id="welcome_simple",
                message="Unykorn code: {code}. Type this code to join. Text STOP to quit.",
                language="en",
                accessibility_friendly=True
            ),
            "referral_en": SMSTemplate(
                template_id="referral_en",
                message="You're invited to join Unykorn! Use code {referral_code} or text START to {phone_number}. Earn tokens for participating!",
                language="en"
            ),
            "referral_simple": SMSTemplate(
                template_id="referral_simple",
                message="Join Unykorn! Text START to {phone_number} with code {referral_code}. Earn money!",
                language="en",
                accessibility_friendly=True
            ),
            "poc_reward": SMSTemplate(
                template_id="poc_reward",
                message="Great! You checked in at {location}. You earned {reward} UNY tokens. Streak: {streak} days. Keep it up!",
                language="en"
            ),
            "commission_earned": SMSTemplate(
                template_id="commission_earned",
                message="Commission earned! {amount} UNY from {referral_name}'s purchase. Total earnings: {total}. View: unykorn.com/dashboard",
                language="en"
            )
        }
        return templates
    
    async def send_verification_sms(
        self,
        phone_number: str,
        user_name: str = "",
        accessibility_friendly: bool = False
    ) -> Tuple[str, bool]:
        """Send SMS verification code"""
        
        # Generate verification code
        verification_code = self._generate_verification_code()
        
        # Store code with expiration
        self.verification_codes[phone_number] = {
            'code': verification_code,
            'expires': datetime.now() + timedelta(minutes=10),
            'attempts': 0
        }
        
        # Select appropriate template
        template_key = "welcome_simple" if accessibility_friendly else "welcome_en"
        template = self.templates[template_key]
        
        # Format message
        message = template.message.format(code=verification_code)
        
        # Send SMS
        success = await self._send_sms(phone_number, message)
        
        if success:
            logger.info(f"Verification SMS sent to {phone_number}")
        else:
            logger.error(f"Failed to send SMS to {phone_number}")
            
        return verification_code, success
    
    async def send_referral_invitation(
        self,
        phone_number: str,
        referral_code: str,
        referrer_name: str = "",
        accessibility_friendly: bool = False
    ) -> bool:
        """Send referral invitation SMS"""
        
        template_key = "referral_simple" if accessibility_friendly else "referral_en"
        template = self.templates[template_key]
        
        # Get system phone number for replies
        system_phone = self.sms_config.get('system_phone', '+1-555-UNYKORN')
        
        message = template.message.format(
            referral_code=referral_code,
            phone_number=system_phone
        )
        
        success = await self._send_sms(phone_number, message)
        
        if success:
            logger.info(f"Referral invitation sent to {phone_number}")
        else:
            logger.error(f"Failed to send referral invitation to {phone_number}")
            
        return success
    
    async def send_reward_notification(
        self,
        phone_number: str,
        reward_type: str,
        amount: int,
        additional_info: Dict[str, str] = None
    ) -> bool:
        """Send reward notification SMS"""
        
        if additional_info is None:
            additional_info = {}
            
        if reward_type == "poc_reward":
            template = self.templates["poc_reward"]
            message = template.message.format(
                location=additional_info.get('location', 'Unknown'),
                reward=amount,
                streak=additional_info.get('streak', 1)
            )
        elif reward_type == "commission_earned":
            template = self.templates["commission_earned"]
            message = template.message.format(
                amount=amount,
                referral_name=additional_info.get('referral_name', 'Someone'),
                total=additional_info.get('total_earnings', amount)
            )
        else:
            # Generic reward message
            message = f"You earned {amount} UNY tokens! View your rewards at unykorn.com/dashboard"
        
        success = await self._send_sms(phone_number, message)
        
        if success:
            logger.info(f"Reward notification sent to {phone_number}")
        else:
            logger.error(f"Failed to send reward notification to {phone_number}")
            
        return success
    
    def verify_sms_code(
        self,
        phone_number: str,
        submitted_code: str
    ) -> Tuple[bool, str]:
        """Verify SMS code"""
        
        if phone_number not in self.verification_codes:
            return False, "No verification code found for this number"
        
        stored_data = self.verification_codes[phone_number]
        
        # Check expiration
        if datetime.now() > stored_data['expires']:
            del self.verification_codes[phone_number]
            return False, "Verification code expired"
        
        # Check attempts
        if stored_data['attempts'] >= 3:
            del self.verification_codes[phone_number]
            return False, "Maximum attempts exceeded"
        
        # Verify code
        if stored_data['code'] == submitted_code:
            del self.verification_codes[phone_number]
            return True, "Verification successful"
        else:
            stored_data['attempts'] += 1
            return False, f"Invalid code. {3 - stored_data['attempts']} attempts remaining"
    
    async def handle_incoming_sms(
        self,
        phone_number: str,
        message_body: str
    ) -> Dict[str, str]:
        """Handle incoming SMS messages"""
        
        message_body = message_body.strip().upper()
        
        if message_body == "START":
            # Start onboarding process
            await self.send_verification_sms(phone_number)
            return {
                'action': 'verification_sent',
                'response': 'Verification code sent! Reply with the code to continue.'
            }
        
        elif message_body == "STOP":
            # Opt out
            return {
                'action': 'opt_out',
                'response': 'You have been unsubscribed from Unykorn SMS notifications.'
            }
        
        elif message_body == "HELP":
            # Help information
            help_text = "Unykorn SMS Help:\nSTART - Begin registration\nSTOP - Unsubscribe\nHELP - This message\nSupport: help@unykorn.com"
            return {
                'action': 'help',
                'response': help_text
            }
        
        elif len(message_body) == 6 and message_body.isdigit():
            # Likely a verification code
            is_valid, result_message = self.verify_sms_code(phone_number, message_body)
            return {
                'action': 'code_verification',
                'is_valid': is_valid,
                'response': result_message
            }
        
        elif message_body.startswith("REF "):
            # Referral code submission
            referral_code = message_body[4:].strip()
            return {
                'action': 'referral_code',
                'referral_code': referral_code,
                'response': f'Referral code {referral_code} received. Verification code will be sent shortly.'
            }
        
        else:
            # Unknown command
            return {
                'action': 'unknown',
                'response': 'Unknown command. Reply HELP for assistance or START to begin registration.'
            }
    
    def _generate_verification_code(self) -> str:
        """Generate 6-digit verification code"""
        return f"{secrets.randbelow(900000) + 100000:06d}"
    
    async def _send_sms(self, phone_number: str, message: str) -> bool:
        """Send SMS using configured provider"""
        
        # Clean phone number
        phone_number = re.sub(r'[^\d+]', '', phone_number)
        if not phone_number.startswith('+'):
            if phone_number.startswith('1') and len(phone_number) == 11:
                phone_number = '+' + phone_number
            elif len(phone_number) == 10:
                phone_number = '+1' + phone_number
        
        provider = self.sms_config.get('provider', 'twilio')
        
        try:
            if provider == 'twilio':
                return await self._send_via_twilio(phone_number, message)
            elif provider == 'aws_sns':
                return await self._send_via_aws_sns(phone_number, message)
            elif provider == 'nexmo':
                return await self._send_via_nexmo(phone_number, message)
            else:
                logger.error(f"Unknown SMS provider: {provider}")
                return False
        except Exception as e:
            logger.error(f"SMS sending failed: {str(e)}")
            return False
    
    async def _send_via_twilio(self, phone_number: str, message: str) -> bool:
        """Send SMS via Twilio"""
        
        account_sid = self.sms_config.get('twilio_account_sid')
        auth_token = self.sms_config.get('twilio_auth_token')
        from_number = self.sms_config.get('twilio_from_number')
        
        if not all([account_sid, auth_token, from_number]):
            logger.error("Twilio credentials not configured")
            return False
        
        url = f"https://api.twilio.com/2010-04-01/Accounts/{account_sid}/Messages.json"
        
        auth = aiohttp.BasicAuth(account_sid, auth_token)
        data = {
            'From': from_number,
            'To': phone_number,
            'Body': message
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, data=data, auth=auth) as response:
                if response.status == 201:
                    logger.info(f"Twilio SMS sent successfully to {phone_number}")
                    return True
                else:
                    error_text = await response.text()
                    logger.error(f"Twilio SMS failed: {response.status} - {error_text}")
                    return False
    
    async def _send_via_aws_sns(self, phone_number: str, message: str) -> bool:
        """Send SMS via AWS SNS"""
        # This would implement AWS SNS SMS sending
        logger.info(f"AWS SNS SMS would be sent to {phone_number}: {message}")
        return True
    
    async def _send_via_nexmo(self, phone_number: str, message: str) -> bool:
        """Send SMS via Nexmo/Vonage"""
        # This would implement Nexmo/Vonage SMS sending
        logger.info(f"Nexmo SMS would be sent to {phone_number}: {message}")
        return True

class AccessibleOnboardingInterface:
    def __init__(self, web3_url: str, contract_address: str, contract_abi: List[Dict]):
        self.web3 = Web3(Web3.HTTPProvider(web3_url))
        self.contract = self.web3.eth.contract(address=contract_address, abi=contract_abi)
        self.qr_generator = QRCodeGenerator()
        self.sms_system = None
        
    def initialize_sms_system(self, sms_config: Dict[str, str]):
        """Initialize SMS system with provider configuration"""
        self.sms_system = SMSOnboardingSystem(sms_config)
        
    async def create_accessible_referral_system(
        self,
        referrer_address: str,
        accessibility_options: AccessibilityOptions
    ) -> Dict[str, str]:
        """Create complete accessible referral system"""
        
        # Generate referral code
        referral_code = self._generate_referral_code(referrer_address)
        
        # Create QR code with accessibility features
        qr_config = QRConfiguration(accessibility=accessibility_options)
        qr_data, qr_image = self.qr_generator.create_referral_qr(
            referrer_address,
            referral_code,
            qr_config
        )
        
        # Encode image as base64
        qr_image_b64 = base64.b64encode(qr_image).decode('utf-8')
        
        # Create simple text instructions
        instructions = self._create_accessibility_instructions(referral_code, accessibility_options)
        
        # Create audio description
        audio_description = self._create_audio_description(referral_code, accessibility_options)
        
        return {
            'referral_code': referral_code,
            'qr_code_data': qr_data,
            'qr_code_image': qr_image_b64,
            'instructions': instructions,
            'audio_description': audio_description,
            'sms_number': self.sms_system.sms_config.get('system_phone', '+1-555-UNYKORN') if self.sms_system else None
        }
    
    async def process_sms_onboarding(
        self,
        phone_number: str,
        message: str,
        accessibility_friendly: bool = False
    ) -> Dict[str, str]:
        """Process SMS-based onboarding"""
        
        if not self.sms_system:
            return {'error': 'SMS system not initialized'}
        
        # Handle incoming SMS
        response = await self.sms_system.handle_incoming_sms(phone_number, message)
        
        # If this starts verification, detect if accessibility features needed
        if response['action'] == 'verification_sent':
            # Could analyze message patterns to detect if user needs accessibility features
            if accessibility_friendly:
                # Resend with accessibility-friendly template
                await self.sms_system.send_verification_sms(
                    phone_number,
                    accessibility_friendly=True
                )
        
        return response
    
    def _generate_referral_code(self, referrer_address: str) -> str:
        """Generate unique referral code"""
        # Create deterministic but secure referral code
        hash_input = f"{referrer_address}{int(datetime.now().timestamp() // 3600)}"  # Changes hourly
        hash_digest = hashlib.sha256(hash_input.encode()).hexdigest()
        return hash_digest[:8].upper()
    
    def _create_accessibility_instructions(
        self,
        referral_code: str,
        accessibility: AccessibilityOptions
    ) -> str:
        """Create text instructions based on accessibility needs"""
        
        if accessibility.simple_language:
            return f"""
JOIN UNYKORN - EASY STEPS:

Method 1 - Phone Camera:
• Open phone camera
• Point at square code
• Tap link that appears

Method 2 - Text Message:
• Text START to +1-555-UNYKORN
• When asked, send: {referral_code}

Method 3 - Website:
• Go to unykorn.com/join
• Enter code: {referral_code}

Need help? Call support: 1-800-UNYKORN
"""
        else:
            return f"""
UNYKORN REFERRAL INSTRUCTIONS:

Your referral code: {referral_code}

To join using this code, you can:

1. QR Code Method:
   - Use your smartphone camera to scan the QR code
   - Tap the notification that appears
   - Complete the registration process

2. SMS Method:
   - Text "START" to +1-555-UNYKORN
   - Reply with your referral code when prompted: {referral_code}
   - Follow the verification steps

3. Web Method:
   - Visit: https://unykorn.com/join
   - Enter referral code: {referral_code}
   - Complete the onboarding process

Support: help@unykorn.com or 1-800-UNYKORN
"""
    
    def _create_audio_description(
        self,
        referral_code: str,
        accessibility: AccessibilityOptions
    ) -> str:
        """Create audio description text for screen readers"""
        
        if accessibility.simple_language:
            return f"""
This is a Unykorn referral invitation. 

To join, you have three easy ways:

First way: Use your phone camera. Point it at the square pattern on screen. Your phone will show a link. Tap the link.

Second way: Send a text message. Text the word START to the number 1-555-UNYKORN. When they ask for your code, send {' '.join(referral_code)}. That's {referral_code}, spelled out.

Third way: Use a computer. Go to unykorn dot com slash join. Type the code {' '.join(referral_code)}.

For help, call 1-800-UNYKORN.
"""
        else:
            return f"""
Audio description for Unykorn referral system.

This page contains a QR code for joining the Unykorn network. 

Your unique referral code is: {' '.join(referral_code)}

You have multiple options to join:

Option 1: QR Code scanning
Use your smartphone camera application to scan the QR code displayed on screen. The QR code contains a link to the registration page with your referral code pre-filled.

Option 2: SMS registration  
Send a text message with the word "START" to +1-555-UNYKORN. You will receive a verification code via SMS. Reply with the verification code to complete registration.

Option 3: Web registration
Navigate to https://unykorn.com/join and enter your referral code manually.

The referral code again is: {' '.join(referral_code)}

For technical support, contact help@unykorn.com or call 1-800-UNYKORN.
"""

async def main():
    """Demo of the QR Code and SMS onboarding system"""
    
    # Configuration
    sms_config = {
        'provider': 'twilio',
        'twilio_account_sid': 'your_account_sid',
        'twilio_auth_token': 'your_auth_token',
        'twilio_from_number': '+1234567890',
        'system_phone': '+1-555-UNYKORN'
    }
    
    web3_url = "http://localhost:8545"
    contract_address = "0x..."  # Your deployed contract
    contract_abi = []  # Your contract ABI
    
    # Initialize system
    onboarding = AccessibleOnboardingInterface(web3_url, contract_address, contract_abi)
    onboarding.initialize_sms_system(sms_config)
    
    # Create accessible referral system for elderly/vision-impaired users
    accessibility_options = AccessibilityOptions(
        high_contrast=True,
        large_text=True,
        audio_description=True,
        simple_language=True,
        font_size=18,
        contrast_ratio="maximum"
    )
    
    referrer_address = "0x742d35Cc6634C0532925a3b8D88f5E04D4C0c8b1"
    
    referral_system = await onboarding.create_accessible_referral_system(
        referrer_address,
        accessibility_options
    )
    
    print("🦄 Unykorn Accessible Onboarding System")
    print("=" * 50)
    print(f"Referral Code: {referral_system['referral_code']}")
    print(f"SMS Number: {referral_system['sms_number']}")
    print("\nInstructions:")
    print(referral_system['instructions'])
    print("\nAudio Description:")
    print(referral_system['audio_description'][:200] + "...")
    
    # Test SMS onboarding
    print("\n📱 Testing SMS Onboarding:")
    
    # Simulate SMS interactions
    phone_number = "+1234567890"
    
    # User sends "START"
    response1 = await onboarding.process_sms_onboarding(
        phone_number, 
        "START", 
        accessibility_friendly=True
    )
    print(f"User: START -> {response1['response']}")
    
    # User sends verification code (simulated)
    response2 = await onboarding.process_sms_onboarding(
        phone_number,
        "123456"  # This would be the actual code sent
    )
    print(f"User: 123456 -> {response2['response']}")
    
    print("\n✅ Accessible onboarding system ready!")

if __name__ == "__main__":
    asyncio.run(main())