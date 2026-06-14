# Proguard rules for SnapStudy
# Prevent R8 compilation failure due to missing optional ML Kit recognizers
-dontwarn com.google.mlkit.vision.text.**
