#!/usr/bin/env node
/**
 * patch-interp.js — In-place ELF64 PT_INTERP patcher for Bun standalone binaries on Termux.
 *
 * Why patchelf cannot be used:
 *   The upstream opencode binary has a 27-byte .interp section ("/lib/ld-linux-aarch64.so.1\0").
 *   Termux's glibc dynamic linker path is 64 bytes long. Running `patchelf --set-interpreter`
 *   relocates ELF program headers/sections to fit the longer path, which corrupts the memory
 *   layout expected by the embedded `.bun` bundle and causes an immediate SIGSEGV (exit 139).
 *
 * How this script works:
 *   It locates the zero-filled alignment padding immediately after the first PT_LOAD segment
 *   (LOAD[0]), writes the 64-byte Termux glibc interpreter path there, updates PT_INTERP to
 *   point to that offset/vaddr, and extends LOAD[0]'s filesz/memsz by 64 bytes. No sections
 *   or offsets move, and the file size remains identical.
 */

const fs = require("fs");
const path = require("path");

const targetFile = process.argv[2] || path.join(process.env.HOME, ".opencode/bin/opencode.bin");
const prefix = process.env.PREFIX || "/data/data/com.termux/files/usr";
const interpPath = process.argv[3] || `${prefix}/glibc/lib/ld-linux-aarch64.so.1`;
const interpBuf = Buffer.from(interpPath + "\0", "utf8");

if (!fs.existsSync(targetFile)) {
  console.error(`Error: Binary not found at ${targetFile}`);
  process.exit(1);
}

const fd = fs.openSync(targetFile, "r+");
const ehdr = Buffer.alloc(64);
fs.readSync(fd, ehdr, 0, 64, 0);

if (ehdr.readUInt32BE(0) !== 0x7f454c46) {
  console.error("Error: Not a valid ELF binary");
  process.exit(1);
}

const phoff = Number(ehdr.readBigUInt64LE(32));
const phentsize = ehdr.readUInt16LE(54);
const phnum = ehdr.readUInt16LE(56);

let interpIdx = -1;
let load0Idx = -1;
let load0 = null;
let load1Offset = Infinity;

for (let i = 0; i < phnum; i++) {
  const ph = Buffer.alloc(phentsize);
  fs.readSync(fd, ph, 0, phentsize, phoff + i * phentsize);
  const p_type = ph.readUInt32LE(0);
  if (p_type === 3 && interpIdx === -1) {
    interpIdx = i;
  } else if (p_type === 1) {
    if (load0Idx === -1) {
      load0Idx = i;
      load0 = ph;
    } else if (load1Offset === Infinity) {
      load1Offset = Number(ph.readBigUInt64LE(8));
    }
  }
}

if (interpIdx === -1 || load0Idx === -1) {
  console.error("Error: Could not find PT_INTERP or PT_LOAD[0] program headers");
  process.exit(1);
}

const p_offset = load0.readBigUInt64LE(8);
const p_vaddr = load0.readBigUInt64LE(16);
const p_filesz = load0.readBigUInt64LE(32);

// Check if already patched at the end of LOAD[0]
const phInterp = Buffer.alloc(phentsize);
fs.readSync(fd, phInterp, 0, phentsize, phoff + interpIdx * phentsize);
const curInterpOffset = Number(phInterp.readBigUInt64LE(8));
const curInterpSize = Number(phInterp.readBigUInt64LE(32));
const curInterpBuf = Buffer.alloc(curInterpSize);
fs.readSync(fd, curInterpBuf, 0, curInterpSize, curInterpOffset);
if (curInterpBuf.equals(interpBuf)) {
  console.log(`PT_INTERP already set to ${interpPath}`);
  fs.closeSync(fd);
  process.exit(0);
}

// Align new interpreter offset to 16 bytes at the end of LOAD[0]
const rawEnd = p_offset + p_filesz;
const newOffset = (rawEnd + 15n) & ~15n;
const newVaddr = p_vaddr + (newOffset - p_offset);
const newSize = BigInt(interpBuf.length);

if (Number(newOffset + newSize) >= load1Offset) {
  console.error("Error: Insufficient padding between LOAD[0] and LOAD[1]");
  process.exit(1);
}

// Write interpreter string into the segment padding
fs.writeSync(fd, interpBuf, 0, interpBuf.length, Number(newOffset));

// Update PT_INTERP program header
phInterp.writeBigUInt64LE(newOffset, 8);
phInterp.writeBigUInt64LE(newVaddr, 16);
phInterp.writeBigUInt64LE(newVaddr, 24);
phInterp.writeBigUInt64LE(newSize, 32);
phInterp.writeBigUInt64LE(newSize, 40);
fs.writeSync(fd, phInterp, 0, phentsize, phoff + interpIdx * phentsize);

// Extend LOAD[0] filesz/memsz to map the new interpreter path
const newLoadSize = (newOffset - p_offset) + newSize;
load0.writeBigUInt64LE(newLoadSize, 32);
load0.writeBigUInt64LE(newLoadSize, 40);
fs.writeSync(fd, load0, 0, phentsize, phoff + load0Idx * phentsize);

fs.closeSync(fd);
console.log(`Patched PT_INTERP -> ${interpPath} (at offset 0x${newOffset.toString(16)})`);
