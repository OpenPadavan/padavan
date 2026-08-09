#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re

SRC = "/home/shutdown/src/padavan/trunk/user/www/dict/BR.dict"
DST = "/home/shutdown/src/padavan/trunk/user/www/dict/PT.dict"

PHRASES = [
    ("para você", "para si"),
    ("com você", "consigo"),
    ("de você", "do seu"),
    ("se você", "se"),
    ("que você", "que"),
]

WORDS = [
    ("senhas", "palavras-passe"),
    ("senha", "palavra-passe"),
    ("Senhas", "Palavras-passe"),
    ("Senha", "Palavra-passe"),
    ("SENHA", "PALAVRA-PASSE"),
    ("telas", "ecrãs"),
    ("tela", "ecrã"),
    ("Telas", "Ecrãs"),
    ("Tela", "Ecrã"),
    ("arquivos", "ficheiros"),
    ("arquivo", "ficheiro"),
    ("Arquivos", "Ficheiros"),
    ("Arquivo", "Ficheiro"),
    ("usuários", "utilizadores"),
    ("usuário", "utilizador"),
    ("Usuários", "Utilizadores"),
    ("Usuário", "Utilizador"),
    ("conexões", "ligações"),
    ("conexão", "ligação"),
    ("Conexões", "Ligações"),
    ("Conexão", "Ligação"),
    ("conectados", "ligados"),
    ("conectado", "ligado"),
    ("Conectado", "Ligado"),
    ("conectar", "ligar"),
    ("Conectar", "Ligar"),
    ("desconectar", "desligar"),
    ("Desconectar", "Desligar"),
    ("salvos", "guardados"),
    ("salvo", "guardado"),
    ("salvar", "guardar"),
    ("Salvar", "Guardar"),
    ("Salvo", "Guardado"),
    ("habilitar", "ativar"),
    ("desabilitar", "desativar"),
    ("Habilitar", "Ativar"),
    ("Desabilitar", "Desativar"),
    ("cadastrar", "registar"),
    ("Cadastrar", "Registar"),
    ("registrar", "registar"),
    ("registro", "registo"),
    ("Registro", "Registo"),
    ("gerenciar", "gerir"),
    ("Gerenciar", "Gerir"),
    ("excluir", "eliminar"),
    ("Excluir", "Eliminar"),
    ("baixar", "transferir"),
    ("Baixar", "Transferir"),
    ("aplicativos", "aplicações"),
    ("aplicativo", "aplicação"),
    ("Aplicativos", "Aplicações"),
    ("Aplicativo", "Aplicação"),
    ("celulares", "telemóveis"),
    ("celular", "telemóvel"),
    ("Celular", "Telemóvel"),
    ("roteadores", "routers"),
    ("roteador", "router"),
    ("Roteador", "Router"),
    ("mouses", "ratos"),
    ("mouse", "rato"),
    ("Mouse", "Rato"),
    ("abas", "separadores"),
    ("aba", "separador"),
    ("configurações", "definições"),
    ("Configurações", "Definições"),
    ("mudar", "alterar"),
    ("Mudar", "Alterar"),
    ("perdias", "perdidas"),
    ("Login", "Entrar"),
    ("Logout", "Sair"),
    ("logout", "terminar a sessão"),
    ("login", "início de sessão"),
]


def apply_words(s):
    for a, b in WORDS:
        s = re.sub(r"\b" + re.escape(a) + r"\b", b, s)
    return s


GERUND_EXC = {"sendo": "ser", "tendo": "ter", "vindo": "vir"}


def fix_gerund(s):
    def repl(m):
        prefix = m.group(1)
        ger = m.group(2)
        if ger in GERUND_EXC:
            inf = GERUND_EXC[ger]
        elif ger.endswith("ando"):
            inf = ger[:-4] + "ar"
        elif ger.endswith("endo"):
            inf = ger[:-4] + "er"
        else:
            inf = ger[:-3] + "ir"
        return prefix + " a " + inf

    s = re.sub(r"\b(está|estão|estava|estavam)\s+([a-zçã-ú]+?)(ando|endo|indo)\b", repl, s)
    return s


def main():
    with open(SRC, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    out = []
    for line in lines:
        if not line or "=" not in line:
            out.append(line)
            continue
        key, val = line.split("=", 1)
        if key == "LANG_BR":
            val = "Português"
            key = "LANG_PT"
        val = val.replace("\\n", "\n").replace("\\t", "\t")
        for a, b in PHRASES:
            val = re.sub(r"\b" + re.escape(a) + r"\b", b, val)
        val = re.sub(r"\bvocê\b", "@@", val, flags=re.IGNORECASE)
        val = re.sub(r"@@\s*([a-zà-ú])", lambda m: m.group(1).upper(), val)
        val = val.replace("@@", "")
        val = fix_gerund(val)
        val = apply_words(val)
        val = re.sub(r" {2,}", " ", val)
        val = val.strip()
        if val and val[0].islower() and re.match(r"^[a-zà-ú]", val[0]):
            val = val[0].upper() + val[1:]
        val = val.replace("\n", "\\n").replace("\t", "\\t")
        out.append(f"{key}={val}")

    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("wrote", DST, len(out), "lines")


if __name__ == "__main__":
    main()
