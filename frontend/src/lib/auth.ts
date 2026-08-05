export const TOKEN_KEY="pr_token";
export const ROLE_KEY="pr_role";
export function getToken():string|null{ if(typeof window==="undefined")return null; return localStorage.getItem(TOKEN_KEY); }
export function getRole():string|null{ if(typeof window==="undefined")return null; return localStorage.getItem(ROLE_KEY); }
export function logout(){ localStorage.removeItem(TOKEN_KEY); localStorage.removeItem(ROLE_KEY); window.location.href="/login"; }
export function isLoggedIn():boolean{ return !!getToken(); }
