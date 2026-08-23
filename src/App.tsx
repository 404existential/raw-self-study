import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./hooks/useAuth";
import { ProtectedRoute } from "./components/ProtectedRoute";
import Home from "./routes/Home";
import Login from "./routes/auth/Login";
import Signup from "./routes/auth/Signup";
import ForgotPassword from "./routes/auth/ForgotPassword";
import ResetPassword from "./routes/auth/ResetPassword";
import AppShell from "./routes/AppShell";

export default function App() {
  return <AuthProvider><BrowserRouter><Routes>
    <Route path="/" element={<Home />} />
    <Route path="/login" element={<Login />} />
    <Route path="/signup" element={<Signup />} />
    <Route path="/forgot-password" element={<ForgotPassword />} />
    <Route path="/reset-password" element={<ResetPassword />} />
    <Route path="/app/*" element={<ProtectedRoute><AppShell /></ProtectedRoute>} />
    <Route path="/dashboard" element={<Navigate to="/app" replace />} />
    <Route path="*" element={<Navigate to="/" replace />} />
  </Routes></BrowserRouter></AuthProvider>;
}
