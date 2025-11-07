package api

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"math/big"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type jwkKey struct{ Kty, Alg, Use, Kid, N, E string }

type jwksSet struct{ Keys []jwkKey `json:"keys"` }

var jwksCache struct{
	mu sync.RWMutex
	keys map[string]*rsa.PublicKey
	expires time.Time
}

func jwksURL() string { if v:=os.Getenv("AUTH_JWKS_URL"); v!=""{return v}; return "http://localhost:8081/.well-known/jwks.json" }

func refreshJWKS() error {
	resp, err := (&http.Client{Timeout: 5*time.Second}).Get(jwksURL())
	if err != nil { return err }
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK { return errors.New("jwks fetch failed") }
	var set jwksSet
	if err := json.NewDecoder(resp.Body).Decode(&set); err != nil { return err }
	m := make(map[string]*rsa.PublicKey)
	for _, k := range set.Keys {
		nBytes, errN := base64.RawURLEncoding.DecodeString(k.N)
		eBytes, errE := base64.RawURLEncoding.DecodeString(k.E)
		if errN != nil || errE != nil { continue }
		n := new(big.Int).SetBytes(nBytes)
		e := new(big.Int).SetBytes(eBytes).Int64(); if e==0 { e=65537 }
		m[k.Kid] = &rsa.PublicKey{N:n, E:int(e)}
	}
	jwksCache.mu.Lock(); jwksCache.keys=m; jwksCache.expires=time.Now().Add(10*time.Minute); jwksCache.mu.Unlock()
	return nil
}

func keyFunc(token *jwt.Token) (interface{}, error) {
	if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok { return nil, jwt.ErrSignatureInvalid }
	jwksCache.mu.RLock(); exp := jwksCache.expires; jwksCache.mu.RUnlock()
	if time.Now().After(exp) || exp.IsZero() { if err := refreshJWKS(); err != nil { return nil, err } }
	kid, _ := token.Header["kid"].(string)
	jwksCache.mu.RLock(); pub := jwksCache.keys[kid]; jwksCache.mu.RUnlock()
	if pub == nil { if err := refreshJWKS(); err != nil { return nil, err }; jwksCache.mu.RLock(); pub = jwksCache.keys[kid]; jwksCache.mu.RUnlock() }
	if pub == nil { return nil, errors.New("kid not found") }
	return pub, nil
}

