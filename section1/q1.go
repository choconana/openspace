package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	mrand "math/rand"
	"strconv"
	"strings"
	"time"
)

func simulatePoW() {
	proofOfWork("0000", true)
	proofOfWork("00000", true)

}

func proofOfWork(zeroString string, isPrinted bool) [32]byte {
	startTime := time.Now()
	var finalHash [32]byte
	for {
		//真随机数耗时太长
		//nonce, _ := rand.Int(rand.Reader, big.NewInt(16))
		nonce := mrand.Int()
		raw := strings.Join([]string{nickName, strconv.Itoa(nonce)}, "")
		hash := sha256.Sum256([]byte(raw))
		hashString := hex.EncodeToString(hash[:])
		if zeroString == hashString[0:len(zeroString)] {
			finalHash = hash
			timeCost := time.Since(startTime)
			if isPrinted {
				fmt.Printf("timeCost: %v, hashContent: %s, hash:%s\n", timeCost, raw, hashString)
			}
			break
		}
	}
	return finalHash
}
