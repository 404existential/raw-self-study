import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "../lib/supabase";

type AuthContextValue = { user: User | null; session: Session | null; loading: boolean; signIn:(email:string,password:string)=>Promise<{error:string|null}>; signUp:(name:string,email:string,password:string)=>Promise<{error:string|null;needsVerification:boolean}>; signOut:()=>Promise<void>; requestPasswordReset:(email:string)=>Promise<{error:string|null}>; updatePassword:(password:string)=>Promise<{error:string|null}> };
const AuthContext=createContext<AuthContextValue|null>(null);
function msg(error: unknown){ return error instanceof Error ? error.message : "Something went wrong. Please try again."; }
export function AuthProvider({children}:{children:ReactNode}){ const [session,setSession]=useState<Session|null>(null); const [loading,setLoading]=useState(true);
 useEffect(()=>{ let mounted=true; supabase.auth.getSession().then(({data})=>{if(mounted){setSession(data.session);setLoading(false)}}); const {data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>{setSession(s);setLoading(false)}); return()=>{mounted=false;subscription.unsubscribe()};},[]);
 async function signIn(email:string,password:string){const {error}=await supabase.auth.signInWithPassword({email:email.trim(),password});return {error:error?msg(error):null};}
 async function signUp(name:string,email:string,password:string){const {data,error}=await supabase.auth.signUp({email:email.trim(),password,options:{data:{full_name:name.trim()}}});return {error:error?msg(error):null,needsVerification:!data.session};}
 async function signOut(){await supabase.auth.signOut({scope:"global"});}
 async function requestPasswordReset(email:string){const {error}=await supabase.auth.resetPasswordForEmail(email.trim(),{redirectTo:`${window.location.origin}/reset-password`});return {error:error?msg(error):null};}
 async function updatePassword(password:string){const {error}=await supabase.auth.updateUser({password});return {error:error?msg(error):null};}
 return <AuthContext.Provider value={{user:session?.user??null,session,loading,signIn,signUp,signOut,requestPasswordReset,updatePassword}}>{children}</AuthContext.Provider> }
export function useAuth(){const ctx=useContext(AuthContext);if(!ctx)throw new Error("useAuth must be used within AuthProvider");return ctx;}
