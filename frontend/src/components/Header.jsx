import { Bell, Wifi, Sparkles, ShieldCheck } from "lucide-react";

function Header() {
  return (
    <header className="header">
      <div className="header-left">
        <p className="header-label">
          AI TELE-OPHTHALMOLOGY SUITE · SIH 2026
        </p>
        <h1>Diabetic Retinopathy Screening</h1>
      </div>

      <div className="header-right">
        {/* Active AI Engine Badge */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            padding: "6px 14px",
            borderRadius: "20px",
            background: "linear-gradient(135deg, rgba(0, 194, 212, 0.1) 0%, rgba(7, 30, 61, 0.05) 100%)",
            border: "1px solid rgba(0, 194, 212, 0.3)",
            fontSize: "12px",
            fontWeight: "600",
            color: "var(--netra-teal-dim)",
          }}
        >
          <span
            style={{
              width: "7px",
              height: "7px",
              borderRadius: "50%",
              background: "#22c55e",
              boxShadow: "0 0 8px #22c55e",
              animation: "pulse 2s infinite",
            }}
          />
          <Sparkles size={13} color="var(--netra-teal)" />
          <span>AI Engine Active · 94.2% Sensitivity</span>
        </div>

        <div className="connection">
          <Wifi size={16} />
          <span>Rural PHC Uplink</span>
        </div>

        <button className="notification-btn" title="System Notifications">
          <Bell size={18} />
        </button>

        <div className="profile">
          <div className="profile-avatar">DR</div>
          <div className="profile-info">
            <strong>Dr. PHC Officer</strong>
            <span>Rural Health Center</span>
          </div>
        </div>
      </div>
    </header>
  );
}

export default Header;