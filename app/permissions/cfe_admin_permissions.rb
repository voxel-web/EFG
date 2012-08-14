module CfeAdminPermissions
  def can_create?(resource)
    [
      AuditorUser,
      CfeAdmin,
      CfeUser,
      LenderAdmin,
      PremiumCollectorUser
    ].include?(resource)
  end

  def can_update?(resource)
    [
      AuditorUser,
      CfeAdmin,
      CfeUser,
      LenderAdmin,
      PremiumCollectorUser
    ].include?(resource)
  end

  def can_view?(resource)
    [
      AuditorUser,
      CfeAdmin,
      CfeUser,
      LenderAdmin,
      PremiumCollectorUser
    ].include?(resource)
  end
end
