import re

p = "/home/shutdown/src/padavan/trunk/user/www/dict/PT.dict"
lines = open(p, encoding="utf-8").read().splitlines()
print("lines:", len(lines))
print("leftover @@:", sum(1 for l in lines if "@@" in l))
print("remaining voce:", sum(1 for l in lines if "você" in l.lower()))
g = [l for l in lines if re.search(r"(está|estão|estava|estavam|vai|ficar|continue)\s+[a-zçã-ú]+(ando|endo|indo)\b", l)]
print("gerund markers:", len(g))
for x in g[:6]:
    print("  ", x)
