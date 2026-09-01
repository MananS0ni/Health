import React, { useState } from 'react';
import { Smartphone, HeartPulse, ArrowRight, CheckCircle2, Lock, MessageSquare, User } from 'lucide-react';

export default function AuthModal({ isOpen, onClose, onLoginSuccess }) {
  const [fullName, setFullName] = useState('Manan Soni');
  const [phoneNumber, setPhoneNumber] = useState('9876543210');
  const [otpCode, setOtpCode] = useState('482910');
  const [step, setStep] = useState(1); // 1: Enter details, 2: Enter OTP
  const [isLoading, setIsLoading] = useState(false);

  if (!isOpen) return null;

  const handleSendOtp = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      setStep(2);
      setOtpCode('482910');
    }, 600);
  };

  const handleVerifyOtp = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onLoginSuccess({
        name: fullName || 'Patient',
        phone: `+91 ${phoneNumber}`,
        status: 'VERIFIED'
      });
      onClose();
    }, 800);
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '420px', borderTop: '6px solid #0F766E' }}>
        
        {/* Modal Header */}
        <div style={{ textAlign: 'center', marginBottom: '1.25rem' }}>
          <div style={{ width: '52px', height: '52px', background: 'linear-gradient(135deg, #0F766E, #14B8A6)', borderRadius: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#FFF', margin: '0 auto 0.75rem auto', boxShadow: '0 4px 12px rgba(15, 118, 110, 0.3)' }}>
            <HeartPulse size={28} />
          </div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0F172A' }}>Patient Portal Registration</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748B', marginTop: '0.2rem' }}>Secure Mobile OTP Access</p>
        </div>

        {/* Form */}
        <div>
          {step === 1 ? (
            <form onSubmit={handleSendOtp}>
              {/* Full Name Input */}
              <div style={{ marginBottom: '1rem' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#334155', marginBottom: '0.4rem' }}>
                  YOUR FULL NAME
                </label>
                <div style={{ position: 'relative' }}>
                  <User size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }} />
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="e.g. Rahul Sharma"
                    style={{ width: '100%', padding: '0.7rem 0.85rem 0.7rem 2.4rem', borderRadius: '10px', border: '1px solid #CBD5E1', fontSize: '0.95rem', fontWeight: 600, outline: 'none' }}
                  />
                </div>
              </div>

              {/* Mobile Number Input */}
              <div style={{ marginBottom: '1.25rem' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#334155', marginBottom: '0.4rem' }}>
                  MOBILE PHONE NUMBER
                </label>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <span style={{ padding: '0.7rem 0.85rem', backgroundColor: '#F8FAFC', border: '1px solid #CBD5E1', borderRadius: '10px', fontWeight: 700, color: '#475569', fontSize: '0.9rem' }}>+91</span>
                  <input
                    type="tel"
                    required
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    placeholder="98765 43210"
                    style={{ flex: 1, padding: '0.7rem 0.85rem', borderRadius: '10px', border: '1px solid #CBD5E1', fontSize: '0.95rem', fontWeight: 600, outline: 'none' }}
                  />
                </div>
              </div>

              {/* Demo Hint Banner */}
              <div style={{ padding: '0.75rem', backgroundColor: '#F0FDF4', borderRadius: '10px', border: '1px solid #BBF7D0', marginBottom: '1.25rem', fontSize: '0.82rem', color: '#166534', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <MessageSquare size={18} style={{ color: '#0F766E' }} />
                <div>
                  <strong>Demo Mode OTP Code:</strong> <code>482910</code>
                </div>
              </div>

              <button
                type="submit"
                className="btn-primary"
                disabled={isLoading}
                style={{ width: '100%', padding: '0.8rem', justifyContent: 'center', fontSize: '0.95rem' }}
              >
                <span>{isLoading ? 'Sending OTP...' : 'Send OTP Code'}</span>
                <ArrowRight size={18} />
              </button>
            </form>
          ) : (
            <form onSubmit={handleVerifyOtp}>
              {/* Demo OTP Alert Box */}
              <div style={{ padding: '0.85rem', backgroundColor: '#ECFDF5', borderRadius: '10px', border: '1px solid #86EFAC', marginBottom: '1.25rem', fontSize: '0.85rem', color: '#166534' }}>
                <div style={{ fontWeight: 800, marginBottom: '0.2rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <MessageSquare size={16} />
                  <span>Demo OTP Code: 482910</span>
                </div>
                <p style={{ fontSize: '0.8rem', color: '#15803D' }}>
                  Verifying patient account for <strong>{fullName}</strong> (+91 {phoneNumber}). Use test code <strong>482910</strong>.
                </p>
              </div>

              <div style={{ marginBottom: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.4rem' }}>
                  <label style={{ fontSize: '0.82rem', fontWeight: 700, color: '#334155' }}>
                    ENTER 6-DIGIT OTP
                  </label>
                  <span style={{ fontSize: '0.78rem', color: '#0F766E', fontWeight: 600 }}>Sent to +91 {phoneNumber}</span>
                </div>
                <input
                  type="text"
                  required
                  maxLength={6}
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  placeholder="482910"
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '2px solid #0F766E', fontSize: '1.2rem', fontWeight: 800, textAlign: 'center', letterSpacing: '8px', outline: 'none', backgroundColor: '#F0FDF4' }}
                />
              </div>

              <button
                type="submit"
                className="btn-primary"
                disabled={isLoading}
                style={{ width: '100%', padding: '0.8rem', justifyContent: 'center', fontSize: '0.95rem', backgroundColor: '#0F766E' }}
              >
                <CheckCircle2 size={18} />
                <span>{isLoading ? 'Verifying...' : 'Verify OTP & Login'}</span>
              </button>

              <button
                type="button"
                onClick={() => setStep(1)}
                style={{ width: '100%', marginTop: '0.75rem', background: 'none', border: 'none', color: '#64748B', fontSize: '0.82rem', fontWeight: 600, cursor: 'pointer' }}
              >
                Change Details
              </button>
            </form>
          )}
        </div>

        {/* Footer */}
        <div style={{ marginTop: '1.5rem', paddingTop: '1rem', borderTop: '1px solid #F1F5F9', textAlign: 'center', fontSize: '0.78rem', color: '#64748B', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.4rem' }}>
          <Lock size={14} style={{ color: '#0F766E' }} />
          <span>Encrypted with 256-Bit SSL Healthcare Security</span>
        </div>
      </div>
    </div>
  );
}
