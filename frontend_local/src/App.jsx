import { BrowserRouter, Routes, Route } from "react-router-dom";

import Sidebar from "./components/Sidebar";
import Header from "./components/Header";
import Analysis from "./pages/Analysis";
import Dashboard from "./pages/Dashboard";
import NewScreening from "./pages/NewScreening";
import ImageQuality from "./pages/ImageQuality";
import Patients from "./pages/Patients";
import Reports from "./pages/Reports";
import Simulation from "./pages/Simulation";
import Results from "./pages/Results";
import DoctorReview from "./pages/DoctorReview";
import ReportGeneration from "./pages/ReportGeneration";

function App() {
  return (
    <BrowserRouter>
      <div className="app">
        <Sidebar />

        <div className="main-area">
          <Header />

          <main>
            <Routes>
              <Route path="/" element={<Dashboard />} />

              <Route
                path="/screening"
                element={<NewScreening />}
              />

              <Route
                path="/image-quality"
                element={<ImageQuality />}
              />

              <Route
                path="/patients"
                element={<Patients />}
              />

              <Route
                path="/reports"
                element={<Reports />}
              />

              <Route 
                path="/analysis" 
                element={<Analysis />} 
              />

              <Route 
                path="/results" 
                element={<Results />} 
              />

              <Route 
                path="/doctor-review" 
                element={<DoctorReview />} 
              />

              <Route
                path="/report-generation"
                element={<ReportGeneration />}
              />

              <Route
                path="/simulation"
                element={<Simulation />}
              />
            </Routes>
          </main>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;