package main

// v0.1.0
// if the **context** missing, use `callerName(2)` as the context:

// v1.0.0
// if the **context** missing, use empty string as the context:

func main() {
	gettext.Gettext("hello")          
	// v0.1.0 => gettext.PGettext("main.main", "hello")
	// v1.0.0 => gettext.PGettext("", "hello")

	gettext.DGettext("domain", "hello")
	// v0.1.0 => gettext.DPGettext("domain", "main.main", "hello")
	// v1.0.0 => gettext.DPGettext("domain", "", "hello")

	gettext.NGettext("domain", "hello", "hello2", n)
	// v0.1.0 => gettext.PNGettext("domain", "main.main", "hello", "hello2", n)
	// v1.0.0 => gettext.PNGettext("domain", "", "hello", "hello2", n)

	gettext.DNGettext("domain", "hello", "hello2", n)
	// v0.1.0 => gettext.DPNGettext("domain", "main.main", "hello", "hello2", n)
	// v1.0.0 => gettext.DPNGettext("domain", "", "hello", "hello2", n)
}
