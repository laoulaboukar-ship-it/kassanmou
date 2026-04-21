async function loadProducts() {
  console.log("CLICK OK");

  try {
    const { data: userData } = await supabase.auth.getUser();

    if (!userData.user) {
      alert("Non connecté");
      return;
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', userData.user.id)
      .single();

    if (!profile || profile.role !== 'admin') {
      alert("Accès refusé");
      return;
    }

    const { data: products, error } = await supabase.from('products').select('*');

    if (error) {
      console.error(error);
      alert("Erreur chargement produits");
      return;
    }

    document.getElementById("products").textContent = JSON.stringify(products, null, 2);

  } catch (e) {
    console.error(e);
    alert("Erreur technique");
  }
}
