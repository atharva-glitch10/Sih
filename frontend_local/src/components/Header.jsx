import { Bell, Wifi } from "lucide-react";

function Header() {
  return (
    <header className="header">

      <div>
        <p className="header-label">
          RURAL PHC TELE-OPHTHALMOLOGY
        </p>

        <h1>
          Diabetic Retinopathy Screening
        </h1>
      </div>

      <div className="header-right">

        <div className="connection">
          <Wifi size={17} />
          <span>Connected</span>
        </div>

        <button className="notification-btn">
          <Bell size={19} />
        </button>

        <div className="profile">

          <div className="profile-avatar">
            PH
          </div>

          <div className="profile-info">
            <strong>PHC Operator</strong>
            <span>Rural PHC</span>
          </div>

        </div>

      </div>

    </header>
  );
}

export default Header;