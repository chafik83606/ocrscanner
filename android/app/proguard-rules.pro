# OCR latin uniquement : le plugin text_recognition référence aussi les scripts
# chinois/devanagari/japonais/coréen, mais ces classes ne sont pas embarquées.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
