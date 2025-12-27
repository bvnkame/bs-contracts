// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Bech32 {
    bytes constant CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

    function encode(
        string memory hrp,
        bytes memory data
    ) internal pure returns (string memory) {
        bytes memory fiveBitData = convertBits(data, 8, 5, true);
        uint[] memory checksum = createChecksum(hrp, fiveBitData);

        bytes memory combined = new bytes(fiveBitData.length + checksum.length);
        for (uint i = 0; i < fiveBitData.length; i++) {
            combined[i] = fiveBitData[i];
        }
        for (uint i = 0; i < checksum.length; i++) {
            combined[fiveBitData.length + i] = bytes1(uint8(checksum[i]));
        }

        return string(
            abi.encodePacked(
                hrp,
                "1",
                encodeChars(combined)
            )
        );
    }

    /* ---------------- internal helpers ---------------- */

    function encodeChars(bytes memory data) internal pure returns (bytes memory) {
        bytes memory out = new bytes(data.length);
        for (uint i = 0; i < data.length; i++) {
            out[i] = CHARSET[uint8(data[i])];
        }
        return out;
    }

    function hrpExpand(string memory hrp) internal pure returns (uint[] memory) {
        bytes memory b = bytes(hrp);
        uint[] memory ret = new uint[](b.length * 2 + 1);
        for (uint i = 0; i < b.length; i++) {
            ret[i] = uint(uint8(b[i]) >> 5);
        }
        ret[b.length] = 0;
        for (uint i = 0; i < b.length; i++) {
            ret[b.length + 1 + i] = uint(uint8(b[i]) & 31);
        }
        return ret;
    }

    function polymod(uint[] memory values) internal pure returns (uint) {
        uint chk = 1;
        uint[5] memory GEN = [
            uint(0x3b6a57b2),
            uint(0x26508e6d),
            uint(0x1ea119fa),
            uint(0x3d4233dd),
            uint(0x2a1462b3)
        ];

        for (uint i = 0; i < values.length; i++) {
            uint top = chk >> 25;
            chk = ((chk & 0x1ffffff) << 5) ^ values[i];
            for (uint j = 0; j < 5; j++) {
                if (((top >> j) & 1) == 1) {
                    chk ^= GEN[j];
                }
            }
        }
        return chk;
    }

    function createChecksum(
        string memory hrp,
        bytes memory data
    ) internal pure returns (uint[] memory) {
        uint[] memory values = concat(hrpExpand(hrp), toUintArray(data));
        uint[] memory extended = new uint[](values.length + 6);
        for (uint i = 0; i < values.length; i++) {
            extended[i] = values[i];
        }

        uint mod = polymod(extended) ^ 1;
        uint[] memory ret;
        for (uint i = 0; i < 6; i++) {
            ret[i] = (mod >> (5 * (5 - i))) & 31;
        }
        return ret;
    }

    function concat(
        uint[] memory a,
        uint[] memory b
    ) internal pure returns (uint[] memory) {
        uint[] memory ret = new uint[](a.length + b.length);
        for (uint i = 0; i < a.length; i++) ret[i] = a[i];
        for (uint i = 0; i < b.length; i++) ret[a.length + i] = b[i];
        return ret;
    }

    function toUintArray(bytes memory data) internal pure returns (uint[] memory) {
        uint[] memory ret = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            ret[i] = uint(uint8(data[i]));
        }
        return ret;
    }

    function convertBits(
        bytes memory data,
        uint fromBits,
        uint toBits,
        bool pad
    ) internal pure returns (bytes memory) {
        uint acc = 0;
        uint bits = 0;
        uint maxv = (1 << toBits) - 1;
        bytes memory ret = new bytes((data.length * fromBits + toBits - 1) / toBits);
        uint index = 0;

        for (uint i = 0; i < data.length; i++) {
            acc = (acc << fromBits) | uint(uint8(data[i]));
            bits += fromBits;
            while (bits >= toBits) {
                bits -= toBits;
                ret[index++] = bytes1(uint8((acc >> bits) & maxv));
            }
        }

        if (pad && bits > 0) {
            ret[index++] = bytes1(uint8((acc << (toBits - bits)) & maxv));
        }

        assembly {
            mstore(ret, index)
        }

        return ret;
    }
}