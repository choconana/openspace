package main

import (
	"crypto"
	crand "crypto/rand"
	"crypto/rsa"
	"fmt"
)

func rsaSign() {
	hash := proofOfWork("0000", false)
	raw := make([]byte, len(hash))
	copy(raw, hash[:])

	privateKey, err := rsa.GenerateKey(crand.Reader, 2048)
	if err != nil {
		panic(err)
	}

	signature, err := rsa.SignPKCS1v15(crand.Reader, privateKey, crypto.SHA256, raw)
	if err != nil {
		panic(err)
	}

	err = rsa.VerifyPKCS1v15(&privateKey.PublicKey, crypto.SHA256, raw, signature)
	if err != nil {
		panic(err)
	}
	fmt.Println("signature verfiy success!")
}
