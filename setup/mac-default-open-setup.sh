brew install duti  # tiny utility for Launch Services
# Sublime Text 4 bundle ID: com.sublimetext.4 (for ST 3 use com.sublimetext.3)
duti -s com.sublimetext.4 public.python-script  all   # .py
duti -s com.sublimetext.4 public.plain-text      all   # .txt, .md, etc.
duti -s com.sublimetext.4 public.json            all   # .json
duti -s com.sublimetext.4 public.yaml            all   # .yml/.yaml
duti -s com.sublimetext.4 public.source-code     all   # .c/.cpp/.js/…

# Inspect a file's UTI
# mdls -name kMDItemContentType -name kMDItemFSName yourfile.ext


# Reset:
# /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister  -kill -r -domain user
