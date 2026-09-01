import React from 'react';
import { X, AlertTriangle, PhoneCall, ShieldAlert, Heart, Activity } from 'lucide-react';

export default function EmergencyCardModal({ isOpen, onClose }) {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ borderTop: '6px solid #0F766E' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{ padding: '0.5rem', backgroundColor: '#FEF2F2', color: '#B91C1C', borderRadius: '8px' }}>
              <ShieldAlert size={24} />
            </div>
            <div>
              <h2 style={{ fontSize: '1.25rem', color: '#0F172A' }}>Emergency Health Access Card</h2>
              <p style={{ fontSize: '0.82rem', color: '#64748B' }}>Instant vital info for first responders & ER doctors</p>
            </div>
          </div>
          <button className="btn-close" onClick={onClose} aria-label="Close modal">
            <X size={20} />
          </button>
        </div>

        {/* Card Content Grid */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Top Info Highlights */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div style={{ padding: '1rem', backgroundColor: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#64748B', textTransform: 'uppercase' }}>Blood Group</span>
              <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#B91C1C', marginTop: '0.2rem' }}>O +ve</div>
            </div>
            <div style={{ padding: '1rem', backgroundColor: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#64748B', textTransform: 'uppercase' }}>Patient Mobile</span>
              <div style={{ fontSize: '0.95rem', fontWeight: 700, color: '#0F766E', marginTop: '0.4rem' }}>+91 98765 43210</div>
            </div>
          </div>

          {/* Allergies & Conditions */}
          <div style={{ padding: '1rem', backgroundColor: '#FFFBEB', borderRadius: '12px', border: '1px solid #FCD34D' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#B45309', fontWeight: 700, fontSize: '0.9rem', marginBottom: '0.5rem' }}>
              <AlertTriangle size={18} />
              <span>Known Medical Allergies</span>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              <span className="badge badge-amber" style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem' }}>Penicillin</span>
              <span className="badge badge-amber" style={{ fontSize: '0.82rem', padding: '0.35rem 0.75rem' }}>Sulfa Antibiotics</span>
            </div>
          </div>

          {/* Emergency Contact */}
          <div style={{ padding: '1rem', backgroundColor: '#F0F9FF', borderRadius: '12px', border: '1px solid #BAE6FD', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <span style={{ fontSize: '0.78rem', color: '#0369A1', fontWeight: 600 }}>PRIMARY EMERGENCY CONTACT</span>
              <div style={{ fontWeight: 700, color: '#0F172A', fontSize: '1rem' }}>Pooja Soni (Kin / Spouse)</div>
              <div style={{ fontSize: '0.9rem', color: '#0284C7', fontWeight: 600 }}>+91 98765 43210</div>
            </div>
            <a href="tel:+919876543210" style={{ textDecoration: 'none' }}>
              <button className="btn-primary" style={{ backgroundColor: '#0284C7' }}>
                <PhoneCall size={16} />
                <span>Call</span>
              </button>
            </a>
          </div>

          {/* QR Code Container */}
          <div style={{ textAlign: 'center', padding: '1.25rem', backgroundColor: '#F8FAFC', borderRadius: '12px', border: '1px dashed #CBD5E1' }}>
            <div style={{ display: 'inline-flex', padding: '1rem', backgroundColor: '#FFFFFF', borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.06)', marginBottom: '0.5rem' }}>
              <svg width="110" height="110" viewBox="0 0 100 100" fill="#0F766E">
                <rect x="0" y="0" width="30" height="30" />
                <rect x="5" y="5" width="20" height="20" fill="#FFF" />
                <rect x="10" y="10" width="10" height="10" fill="#0F766E" />
                <rect x="70" y="0" width="30" height="30" />
                <rect x="75" y="5" width="20" height="20" fill="#FFF" />
                <rect x="80" y="10" width="10" height="10" fill="#0F766E" />
                <rect x="0" y="70" width="30" height="30" />
                <rect x="5" y="75" width="20" height="20" fill="#FFF" />
                <rect x="10" y="80" width="10" height="10" fill="#0F766E" />
                <rect x="40" y="40" width="20" height="20" />
                <rect x="70" y="70" width="15" height="15" />
                <rect x="40" y="10" width="15" height="15" />
                <rect x="10" y="40" width="15" height="15" />
              </svg>
            </div>
            <p style={{ fontSize: '0.8rem', color: '#64748B', fontWeight: 500 }}>Scan QR to view verified emergency medical summary</p>
          </div>
        </div>
      </div>
    </div>
  );
}
