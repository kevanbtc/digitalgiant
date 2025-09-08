"use client";

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { 
  Menu, 
  X, 
  Home, 
  Info, 
  Star, 
  DollarSign, 
  Phone,
  LogIn,
  UserPlus
} from 'lucide-react';

const navigation = [
  { name: 'Home', href: '/', icon: Home },
  { name: 'About', href: '/about', icon: Info },
  { name: 'Features', href: '/features', icon: Star },
  { name: 'Pricing', href: '/pricing', icon: DollarSign },
  { name: 'Contact', href: '/contact', icon: Phone },
];

export function Header() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = React.useState(false);
  const pathname = usePathname();

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between">
        {/* Skip to main content link for accessibility */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 bg-primary text-primary-foreground px-4 py-2 rounded-md z-50"
        >
          Skip to main content
        </a>

        {/* Logo */}
        <Link 
          href="/" 
          className="flex items-center space-x-2 font-bold text-xl"
          aria-label="Digital Giant - Home"
        >
          <span className="text-primary">🏗️</span>
          <span>Digital Giant</span>
        </Link>

        {/* Desktop Navigation */}
        <nav 
          className="hidden md:flex items-center space-x-6"
          aria-label="Main navigation"
        >
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "flex items-center space-x-2 text-sm font-medium transition-colors hover:text-primary",
                  pathname === item.href
                    ? "text-primary"
                    : "text-muted-foreground"
                )}
                aria-current={pathname === item.href ? 'page' : undefined}
              >
                <Icon className="h-4 w-4" aria-hidden="true" />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* Desktop Auth Buttons */}
        <div className="hidden md:flex items-center space-x-4">
          <Button variant="ghost" asChild>
            <Link href="/auth/login" className="flex items-center space-x-2">
              <LogIn className="h-4 w-4" aria-hidden="true" />
              <span>Login</span>
            </Link>
          </Button>
          <Button asChild>
            <Link href="/auth/register" className="flex items-center space-x-2">
              <UserPlus className="h-4 w-4" aria-hidden="true" />
              <span>Get Started</span>
            </Link>
          </Button>
        </div>

        {/* Mobile Menu Button */}
        <Button
          variant="ghost"
          size="icon"
          className="md:hidden"
          onClick={toggleMobileMenu}
          aria-expanded={isMobileMenuOpen}
          aria-controls="mobile-menu"
          aria-label="Toggle mobile menu"
        >
          {isMobileMenuOpen ? (
            <X className="h-6 w-6" aria-hidden="true" />
          ) : (
            <Menu className="h-6 w-6" aria-hidden="true" />
          )}
        </Button>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div 
          id="mobile-menu"
          className="md:hidden border-t bg-background"
        >
          <nav className="container py-4 space-y-4" aria-label="Mobile navigation">
            {navigation.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    "flex items-center space-x-3 px-4 py-2 rounded-md text-sm font-medium transition-colors hover:bg-accent",
                    pathname === item.href
                      ? "text-primary bg-accent"
                      : "text-muted-foreground"
                  )}
                  onClick={() => setIsMobileMenuOpen(false)}
                  aria-current={pathname === item.href ? 'page' : undefined}
                >
                  <Icon className="h-5 w-5" aria-hidden="true" />
                  <span>{item.name}</span>
                </Link>
              );
            })}
            
            <div className="border-t pt-4 space-y-2">
              <Link
                href="/auth/login"
                className="flex items-center space-x-3 px-4 py-2 rounded-md text-sm font-medium text-muted-foreground hover:bg-accent transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <LogIn className="h-5 w-5" aria-hidden="true" />
                <span>Login</span>
              </Link>
              <Link
                href="/auth/register"
                className="flex items-center space-x-3 px-4 py-2 rounded-md text-sm font-medium bg-primary text-primary-foreground hover:bg-primary/90 transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <UserPlus className="h-5 w-5" aria-hidden="true" />
                <span>Get Started</span>
              </Link>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}