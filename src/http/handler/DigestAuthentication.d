module http.handler.DigestAuthentication;

import http.handler.Handler;
import dlog.Logger;

class DigestAuthentication : Handler
{
    private
    {
        string m_realm;
        string m_nonce;
        string m_opaque;
        string m_algorithm;
        string m_qop;
        bool   m_stale;
        string m_domain;
    }

    override protected bool execute(Transaction transaction)
    {
        mixin(Tracer);
        return true;
    }
}
