import requests

def define_env(env):
    """
    This is the hook for the functions (new form)
    """

    @env.macro
    def makeS3Links(baseFile):
        "Make S3 Links for file, checksum and Signature"

        return f"[Download]({baseFile} \"{baseFile}\") \| [Checksum]({baseFile}.sha256 \"{baseFile}.sha256\") \| [Signature]({baseFile}.sha256.asc \"{baseFile}.sha256.asc\")"