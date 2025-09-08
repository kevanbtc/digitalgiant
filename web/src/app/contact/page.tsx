import { Metadata } from 'next';
import { MainLayout } from '@/components/layout/main-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { SUPPORT_PHONE, SUPPORT_EMAIL, SUPPORT_HOURS } from '@/lib/constants';
import Link from 'next/link';
import {
  Phone,
  Mail,
  Clock,
  MapPin,
  MessageSquare,
  Users,
  DollarSign,
  Shield,
  HelpCircle,
  Send,
  Calendar,
} from 'lucide-react';

export const metadata: Metadata = {
  title: 'Contact Us',
  description: 'Get in touch with Digital Giant. We\'re here to help you succeed in the connection economy.',
};

const contactMethods = [
  {
    icon: Phone,
    title: 'Phone Support',
    description: SUPPORT_PHONE,
    details: SUPPORT_HOURS,
    action: `tel:${SUPPORT_PHONE}`,
    actionText: 'Call Now',
  },
  {
    icon: Mail,
    title: 'Email Support',
    description: SUPPORT_EMAIL,
    details: 'Response within 24 hours',
    action: `mailto:${SUPPORT_EMAIL}`,
    actionText: 'Send Email',
  },
  {
    icon: MessageSquare,
    title: 'Live Chat',
    description: 'Chat with our team',
    details: 'Available during business hours',
    action: '#',
    actionText: 'Start Chat',
  },
  {
    icon: Calendar,
    title: 'Schedule Demo',
    description: 'Book a personal demo',
    details: '30-minute consultation',
    action: '/demo',
    actionText: 'Book Demo',
  },
];

const departments = [
  {
    icon: Users,
    title: 'Sales & Partnerships',
    email: 'sales@digitalgiant.com',
    description: 'Business inquiries, partnerships, and enterprise solutions',
  },
  {
    icon: Shield,
    title: 'Security & Compliance',
    email: 'security@digitalgiant.com',
    description: 'Security issues, compliance questions, and audit requests',
  },
  {
    icon: DollarSign,
    title: 'Billing & Payments',
    email: 'billing@digitalgiant.com',
    description: 'Payment issues, refunds, and billing questions',
  },
  {
    icon: HelpCircle,
    title: 'General Support',
    email: SUPPORT_EMAIL,
    description: 'General questions, technical support, and platform help',
  },
];

const faqs = [
  {
    question: 'How do I get started?',
    answer: 'Simply sign up for a free account, choose your pack, and start inviting your network. We provide full onboarding support.',
  },
  {
    question: 'Is Digital Giant legitimate?',
    answer: 'Yes, we are a registered company with enterprise-grade security, professional custody, and full regulatory compliance.',
  },
  {
    question: 'How quickly can I start earning?',
    answer: 'You can start earning immediately after your first successful referral. Payments are processed within 24 hours.',
  },
  {
    question: 'What kind of support do you provide?',
    answer: 'We offer 24/7 phone support, live chat, email support, training materials, and dedicated account managers for enterprise clients.',
  },
];

const officeLocations = [
  {
    city: 'New York',
    address: '123 Digital Avenue, Suite 500, New York, NY 10001',
    phone: '+1 (212) 555-0123',
  },
  {
    city: 'San Francisco',
    address: '456 Tech Street, Floor 10, San Francisco, CA 94105',
    phone: '+1 (415) 555-0124',
  },
  {
    city: 'Chicago',
    address: '789 Business Plaza, Suite 200, Chicago, IL 60601',
    phone: '+1 (312) 555-0125',
  },
];

export default function ContactPage() {
  return (
    <MainLayout>
      {/* Hero Section */}
      <section className="py-20 md:py-32 px-4 bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Get in{' '}
              <span className="text-primary">Touch</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto">
              We're here to help you succeed in the connection economy. 
              Reach out for support, partnerships, or just to say hello.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" asChild>
                <Link href={`tel:${SUPPORT_PHONE}`}>
                  <Phone className="mr-2 h-5 w-5" />
                  Call {SUPPORT_PHONE}
                </Link>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <Link href="#contact-form">
                  <Mail className="mr-2 h-5 w-5" />
                  Send Message
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Contact Methods */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Multiple Ways to Connect</h2>
            <p className="text-xl text-muted-foreground">
              Choose the method that works best for you
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {contactMethods.map((method, index) => {
              const Icon = method.icon;
              return (
                <Card key={index} className="text-center h-full">
                  <CardHeader>
                    <div className="w-16 h-16 bg-primary/10 rounded-xl flex items-center justify-center mx-auto mb-4">
                      <Icon className="h-8 w-8 text-primary" />
                    </div>
                    <CardTitle className="text-xl">{method.title}</CardTitle>
                    <CardDescription className="font-medium">
                      {method.description}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-muted-foreground mb-4">
                      {method.details}
                    </p>
                    <Button variant="outline" className="w-full" asChild>
                      <Link href={method.action}>
                        {method.actionText}
                      </Link>
                    </Button>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Contact Form */}
      <section id="contact-form" className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-4 mb-16">
              <h2 className="text-3xl md:text-4xl font-bold">Send Us a Message</h2>
              <p className="text-xl text-muted-foreground">
                We'll get back to you within 24 hours
              </p>
            </div>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
              {/* Contact Form */}
              <Card>
                <CardHeader>
                  <CardTitle>Contact Form</CardTitle>
                  <CardDescription>
                    Fill out the form below and we'll get back to you soon
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <form className="space-y-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <Input
                        label="First Name"
                        placeholder="John"
                        required
                      />
                      <Input
                        label="Last Name"
                        placeholder="Doe"
                        required
                      />
                    </div>
                    
                    <Input
                      label="Email"
                      type="email"
                      placeholder="john@example.com"
                      required
                    />
                    
                    <Input
                      label="Phone (Optional)"
                      type="tel"
                      placeholder="+1 (555) 123-4567"
                    />
                    
                    <div>
                      <label className="text-sm font-medium leading-none mb-2 block">
                        Subject
                      </label>
                      <select className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
                        <option value="">Select a topic</option>
                        <option value="general">General Inquiry</option>
                        <option value="sales">Sales & Partnerships</option>
                        <option value="support">Technical Support</option>
                        <option value="billing">Billing & Payments</option>
                        <option value="security">Security & Compliance</option>
                      </select>
                    </div>
                    
                    <div>
                      <label className="text-sm font-medium leading-none mb-2 block">
                        Message
                      </label>
                      <textarea
                        className="flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                        placeholder="Tell us how we can help you..."
                        required
                      />
                    </div>
                    
                    <Button className="w-full" size="lg">
                      <Send className="mr-2 h-4 w-4" />
                      Send Message
                    </Button>
                  </form>
                </CardContent>
              </Card>
              
              {/* Department Info */}
              <div className="space-y-6">
                <Card>
                  <CardHeader>
                    <CardTitle>Department Contacts</CardTitle>
                    <CardDescription>
                      For specific inquiries, contact the right department directly
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {departments.map((dept, index) => {
                        const Icon = dept.icon;
                        return (
                          <div key={index} className="flex items-start space-x-3 p-3 bg-muted/50 rounded-lg">
                            <Icon className="h-5 w-5 text-primary mt-0.5" />
                            <div className="flex-1">
                              <div className="font-semibold text-sm">{dept.title}</div>
                              <div className="text-xs text-muted-foreground mb-1">
                                {dept.description}
                              </div>
                              <Link 
                                href={`mailto:${dept.email}`}
                                className="text-xs text-primary hover:underline"
                              >
                                {dept.email}
                              </Link>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center space-x-2">
                      <Clock className="h-5 w-5 text-primary" />
                      <span>Support Hours</span>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span>Phone Support:</span>
                        <span className="font-medium">{SUPPORT_HOURS}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Live Chat:</span>
                        <span className="font-medium">Mon-Fri 9AM-6PM EST</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Email Support:</span>
                        <span className="font-medium">24/7</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Emergency Line:</span>
                        <span className="font-medium">24/7/365</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Office Locations */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Our Offices</h2>
            <p className="text-xl text-muted-foreground">
              Visit us at one of our locations
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {officeLocations.map((office, index) => (
              <Card key={index} className="text-center">
                <CardHeader>
                  <MapPin className="h-8 w-8 text-primary mx-auto mb-2" />
                  <CardTitle className="text-xl">{office.city}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <p className="text-muted-foreground">{office.address}</p>
                    <p className="font-medium">{office.phone}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Quick Answers</h2>
            <p className="text-xl text-muted-foreground">
              Common questions we receive
            </p>
          </div>
          
          <div className="max-w-3xl mx-auto space-y-6">
            {faqs.map((faq, index) => (
              <Card key={index}>
                <CardHeader>
                  <CardTitle className="text-lg">{faq.question}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">{faq.answer}</p>
                </CardContent>
              </Card>
            ))}
          </div>
          
          <div className="text-center mt-12">
            <Button variant="outline" asChild>
              <Link href="/faq">
                View All FAQs
              </Link>
            </Button>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 bg-primary text-primary-foreground">
        <div className="container mx-auto text-center">
          <div className="max-w-3xl mx-auto space-y-8">
            <h2 className="text-3xl md:text-4xl font-bold">
              Ready to Get Started?
            </h2>
            <p className="text-xl opacity-90">
              Don't wait - join thousands of connection masters already building their digital empires.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" asChild>
                <Link href="/auth/register">
                  Join Digital Giant
                </Link>
              </Button>
              <Button 
                size="lg" 
                variant="outline" 
                className="border-primary-foreground text-primary-foreground hover:bg-primary-foreground hover:text-primary" 
                asChild
              >
                <Link href="/demo">
                  Schedule Demo
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </MainLayout>
  );
}