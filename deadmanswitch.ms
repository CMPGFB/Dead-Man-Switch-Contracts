or_d(
    pk(owner_key),  // Owner can always spend
    and_v(
        older(timeout),  // If timeout expires
        pk(beneficiary_key)  // Beneficiary can spend
    )
)
