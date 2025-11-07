package api

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"os"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// JWKS structures
type jwkKey struct {
	Kty string `json:"kty"`
	Alg string `json:"alg"`
	Use string `json:"use"`
	Kid string `json:"kid"`
	N   string `json:"n"`
	E   string `json:"e"`
}

type jwksResponse struct {
	Keys []jwkKey `json:"keys"`
}

var (
	keysOnce    sync.Once
	keysOnceErr error
	rsaPrivKey  *rsa.PrivateKey
	rsaPubKey   *rsa.PublicKey
	computedKID string
	computedJWK jwkKey
)

func loadRS256KeysOnce() error {
	keysOnce.Do(func() {
		pemPath := strings.TrimSpace(os.Getenv("JWT_PRIVATE_KEY_PATH"))
		pemInline := strings.TrimSpace(os.Getenv("JWT_PRIVATE_KEY_PEM"))
		var pemBytes []byte
		if pemPath != "" {
			b, err := os.ReadFile(pemPath)
			if err != nil {
				keysOnceErr = fmt.Errorf("read private key: %w", err)
				return
			}
			pemBytes = b
		} else if pemInline != "" {
			pemBytes = []byte(pemInline)
		} else {
			keysOnceErr = errors.New("JWT_PRIVATE_KEY_PATH or JWT_PRIVATE_KEY_PEM must be set")
			return
		}
		block, _ := pem.Decode(pemBytes)
		if block == nil {
			keysOnceErr = errors.New("invalid PEM for RSA private key")
			return
		}
		pk, err := x509.ParsePKCS1PrivateKey(block.Bytes)
		if err != nil {
			// try PKCS8
			if k, e2 := x509.ParsePKCS8PrivateKey(block.Bytes); e2 == nil {
				var ok bool
				rsaPrivKey, ok = k.(*rsa.PrivateKey)
				if !ok {
					keysOnceErr = errors.New("PKCS8 key is not RSA")
					return
				}
			} else {
				keysOnceErr = fmt.Errorf("parse private key: %v / %v", err, e2)
				return
			}
		} else {
			rsaPrivKey = pk
		}
		rsaPubKey = &rsaPrivKey.PublicKey

		// kid: SHA-256 over SubjectPublicKeyInfo DER
		spki, err := x509.MarshalPKIXPublicKey(rsaPubKey)
		if err != nil {
			keysOnceErr = fmt.Errorf("marshal pub: %w", err)
			return
		}
		h := sha256.Sum256(spki)
		computedKID = base64.RawURLEncoding.EncodeToString(h[:])

		// Build JWK
		n := base64.RawURLEncoding.EncodeToString(rsaPubKey.N.Bytes())
		e := base64.RawURLEncoding.EncodeToString(big.NewInt(int64(rsaPubKey.E)).Bytes())
		computedJWK = jwkKey{Kty: "RSA", Alg: "RS256", Use: "sig", Kid: computedKID, N: n, E: e}
	})
	return keysOnceErr
}

func getRSAPrivateKey() (*rsa.PrivateKey, error) {
	if err := loadRS256KeysOnce(); err != nil {
		return nil, err
	}
	return rsaPrivKey, nil
}

func getRSAPublicKey() (*rsa.PublicKey, error) {
	if err := loadRS256KeysOnce(); err != nil {
		return nil, err
	}
	return rsaPubKey, nil
}

func getJWKSKey() (jwkKey, error) {
	if err := loadRS256KeysOnce(); err != nil {
		return jwkKey{}, err
	}
	return computedJWK, nil
}

// JWKS endpoint handler
func (h *Handler) JWKS(c *gin.Context) {
	if err := loadRS256KeysOnce(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "keys not configured", "detail": err.Error()})
		return
	}
	jwk := computedJWK
	resp := jwksResponse{Keys: []jwkKey{jwk}}
	c.Header("Cache-Control", "public, max-age=300")
	c.JSON(http.StatusOK, resp)
}

// Helper to sign with RS256 and set kid
func signJWTWithRS256(claims map[string]interface{}) (string, error) {
	if err := loadRS256KeysOnce(); err != nil {
		return "", err
	}
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims(claims))
	token.Header["kid"] = computedKID
	return token.SignedString(rsaPrivKey)
}

// Local self-check utility (never called in prod code path, can be used in tests)
func generateDevKeyPairIfMissing() error {
	pemPath := strings.TrimSpace(os.Getenv("JWT_PRIVATE_KEY_PATH"))
	if pemPath == "" {
		return nil
	}
	if _, err := os.Stat(pemPath); err == nil {
		return nil
	}
	// generate quick dev key
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return err
	}
	b := x509.MarshalPKCS1PrivateKey(k)
	pemBytes := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: b})
	if err := os.MkdirAll(strings.TrimSuffix(pemPath, "/jwt_rsa_private.pem"), 0700); err != nil {
		return err
	}
	return os.WriteFile(pemPath, pemBytes, 0600)
}
