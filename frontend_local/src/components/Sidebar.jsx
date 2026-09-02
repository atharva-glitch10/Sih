import {
  LayoutDashboard,
  ScanEye,
  Users,
  FileText,
  Activity,
} from "lucide-react";

import { NavLink } from "react-router-dom";

function Sidebar() {

  const navItems = [
    {
      name: "Dashboard",
      path: "/",
      icon: LayoutDashboard,
    },
    {
      name: "New Screening",
      path: "/screening",
      icon: ScanEye,
    },
    {
      name: "Patients",
      path: "/patients",
      icon: Users,
    },
    {
      name: "Reports",
      path: "/reports",
      icon: FileText,
    },
    {
      name: "Simulation",
      path: "/simulation",
      icon: Activity,
    },
  ];

  return (
    <aside className="sidebar">

      {/* Logo */}

      <div className="logo-section">

        <div className="logo-icon">
          <ScanEye size={25} />
        </div>

        <div>
          <h2>NETRA</h2>
          <span>AI Screening</span>
        </div>

      </div>


      {/* Navigation */}

      <nav className="sidebar-nav">

        {navItems.map((item) => {

          const Icon = item.icon;

          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                isActive
                  ? "nav-item active"
                  : "nav-item"
              }
            >

              <Icon size={20} />

              <span>
                {item.name}
              </span>

            </NavLink>
          );

        })}

      </nav>


      {/* System status */}

      <div className="sidebar-bottom">

        <div className="online-dot"></div>

        <div>
          <strong>System Online</strong>
          <span>AI Engine Ready</span>
        </div>

      </div>

    </aside>
  );
}

export default Sidebar;