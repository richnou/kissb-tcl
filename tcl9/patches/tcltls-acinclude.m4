--- acinclude.m4
+++ acinclude.m4
@@ -232,12 +232,16 @@
 			pkgConfigExtraArgs='--static'
 		fi
 
+      
 		if test -z "$TCLTLS_SSL_LIBS"; then
-			TCLTLS_SSL_LIBS="$SSL_LIBS_PATH `${PKG_CONFIG} openssl --libs $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])
-			if test "${TCLEXT_TLS_STATIC_SSL}" == 'yes'; then
+
+            TCLTLS_SSL_LIBS="$SSL_LIBS_PATH `${PKG_CONFIG} openssl --libs $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])  
+		fi
+        
+        if test "${TCLEXT_TLS_STATIC_SSL}" == 'yes'; then
 				TCLTLS_SSL_LIBS="-Wl,-Bstatic $TCLTLS_SSL_LIBS -Wl,-Bdynamic"
-			fi
-		fi
+        fi
+
 		if test -z "$TCLTLS_SSL_CFLAGS"; then
 			TCLTLS_SSL_CFLAGS="`"${PKG_CONFIG}" openssl --cflags-only-other $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])
 		fi
