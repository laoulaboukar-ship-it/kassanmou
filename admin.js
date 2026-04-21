async function loadProducts() {
  console.log("CLICK OK");

  try {
    const { data: userData } = await supabase.auth.getUser();
    console.log("USER:", userData);

    if (!userData.user) {
      alert("Non connecté");
      return;
    }

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', userData.user.id)
      .single();

    console.log("PROFILE:", profile, profileError);

    if (!profile || profile.role !== 'admin') {
      alert("Accès refusé");
      return;
    }

    const { data: products, error } = await supabase.from('products').select('*');

    console.log("PRODUCTS:", products, error);

    document.getElementById("products").textContent = JSON.stringify(products, null, 2);

  } catch (e) {
    console.error("ERROR:", e);
    alert("Erreur technique");
  }
}
