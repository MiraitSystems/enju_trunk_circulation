module Util
  def base64decode(base64encoded)
    if (base64encoded == nil || !base64encoded.length) 
      return ""
    end
    return Base64.decode64(base64encoded)
  end

class Cryptor
  def decrypt(encrypted)
    if (encrypted == nil || !encrypted.length) 
      return ""
    end

    @decryptor.reset
    @decryptor.key = @key
    @decryptor.iv = @iv
    decrypted = ""
    decrypted << @decryptor.update(encrypted)
    decrypted << @decryptor.final

    return decrypted;
  end

  def initialize(passwd)
    salt = "salt_for_key_and_iv"
    @decryptor = OpenSSL::Cipher.new("AES-256-CBC")
    @decryptor.decrypt

    # 共有キーと初期化ベクタを生成, 反復処理回数:2000
    key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(passwd, salt, 2000, @decryptor.key_len + @decryptor.iv_len)
    @key = key_iv[0, @decryptor.key_len]
    @iv = key_iv[@decryptor.key_len, @decryptor.iv_len]
  end
end
end
