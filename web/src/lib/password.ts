// No 0/O, 1/l/I: these passwords are read out or typed from a note.
const ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";

/** A random password like `k7qm-x3pv-9tdw-hn4e` (~79 bits). */
export function generatePassword(): string {
  const chars: string[] = [];
  const limit = 256 - (256 % ALPHABET.length); // reject the tail to avoid modulo bias
  while (chars.length < 16) {
    for (const b of crypto.getRandomValues(new Uint8Array(32))) {
      if (b < limit && chars.length < 16) chars.push(ALPHABET[b % ALPHABET.length]);
    }
  }
  return chars.join("").match(/.{4}/g)!.join("-");
}
