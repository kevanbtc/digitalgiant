import React from 'react';
import Link from 'next/link';
import { SUPPORT_PHONE, SUPPORT_EMAIL } from '@/lib/constants';

const footerSections = [
  {
    title: 'Product',
    links: [
      { name: 'Features', href: '/features' },
      { name: 'Pricing', href: '/pricing' },
      { name: 'How It Works', href: '/how-it-works' },
      { name: 'Roadmap', href: '/roadmap' },
    ],
  },
  {
    title: 'Company',
    links: [
      { name: 'About', href: '/about' },
      { name: 'Team', href: '/team' },
      { name: 'Careers', href: '/careers' },
      { name: 'Press', href: '/press' },
    ],
  },
  {
    title: 'Resources',
    links: [
      { name: 'Documentation', href: '/docs' },
      { name: 'API Reference', href: '/docs/api' },
      { name: 'Tutorials', href: '/tutorials' },
      { name: 'FAQ', href: '/faq' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { name: 'Privacy Policy', href: '/privacy' },
      { name: 'Terms of Service', href: '/terms' },
      { name: 'Cookie Policy', href: '/cookies' },
      { name: 'Compliance', href: '/compliance' },
    ],
  },
];

const socialLinks = [
  { name: 'Twitter', href: 'https://twitter.com/digitalgiant_', icon: '𝕏' },
  { name: 'Discord', href: 'https://discord.gg/digitalgiant', icon: '💬' },
  { name: 'Telegram', href: 'https://t.me/digitalgiant', icon: '📱' },
  { name: 'LinkedIn', href: 'https://linkedin.com/company/digitalgiant', icon: '💼' },
];

export function Footer() {
  return (
    <footer className="border-t bg-background">
      <div className="container px-4 py-12 md:py-16">
        {/* Main Footer Content */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-8">
          {/* Brand Section */}
          <div className="lg:col-span-2 space-y-4">
            <Link 
              href="/" 
              className="flex items-center space-x-2 font-bold text-xl"
              aria-label="Digital Giant - Home"
            >
              <span className="text-primary">🏗️</span>
              <span>Digital Giant</span>
            </Link>
            <p className="text-sm text-muted-foreground max-w-xs">
              Empowering Connection Masters to Build Their Digital Empire. 
              Where relationships become currency.
            </p>
            <div className="space-y-2 text-sm text-muted-foreground">
              <div className="flex items-center space-x-2">
                <span>📞</span>
                <a 
                  href={`tel:${SUPPORT_PHONE}`}
                  className="hover:text-primary transition-colors"
                  aria-label={`Call support at ${SUPPORT_PHONE}`}
                >
                  {SUPPORT_PHONE}
                </a>
              </div>
              <div className="flex items-center space-x-2">
                <span>✉️</span>
                <a 
                  href={`mailto:${SUPPORT_EMAIL}`}
                  className="hover:text-primary transition-colors"
                  aria-label={`Email support at ${SUPPORT_EMAIL}`}
                >
                  {SUPPORT_EMAIL}
                </a>
              </div>
            </div>
          </div>

          {/* Footer Links */}
          {footerSections.map((section) => (
            <div key={section.title} className="space-y-4">
              <h3 className="text-sm font-semibold">{section.title}</h3>
              <ul className="space-y-2">
                {section.links.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-sm text-muted-foreground hover:text-primary transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom Section */}
        <div className="mt-12 pt-8 border-t">
          <div className="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0">
            {/* Copyright */}
            <div className="text-sm text-muted-foreground">
              © 2024 Digital Giant. All rights reserved.
            </div>

            {/* Social Links */}
            <div className="flex items-center space-x-4">
              <span className="text-sm text-muted-foreground">Follow us:</span>
              {socialLinks.map((social) => (
                <a
                  key={social.name}
                  href={social.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground hover:text-primary transition-colors"
                  aria-label={`Follow us on ${social.name} (opens in new tab)`}
                >
                  <span className="text-lg" aria-hidden="true">
                    {social.icon}
                  </span>
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* Accessibility Statement */}
        <div className="mt-8 pt-4 border-t">
          <p className="text-xs text-muted-foreground text-center">
            Digital Giant is committed to accessibility. Our platform meets WCAG 2.1 AA standards.{' '}
            <Link 
              href="/accessibility" 
              className="underline hover:text-primary transition-colors"
            >
              Learn more about our accessibility features
            </Link>
          </p>
        </div>
      </div>
    </footer>
  );
}