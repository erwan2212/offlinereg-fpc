unit ubcd;

interface

const
/// <summary>
    /// Represents a Boot Configuration Database object (application, device or inherited settings).
    /// </summary>

   
        /// <summary>
        /// Well-known object for Emergency Management Services settings.
        /// </summary>
         EmsSettingsGroupId = '{0CE4991B-E6B3-4B16-B23C-5E0D9250E5D9}';

        /// <summary>
        /// Well-known object for the Resume boot loader.
        /// </summary>
         ResumeLoaderSettingsGroupId = '{1AFA9C49-16AB-4A5C-4A90-212802DA9460}';

        /// <summary>
        /// Alias for the Default boot entry.
        /// </summary>
         DefaultBootEntryId = '{1CAE1EB7-A0DF-4D4D-9851-4860E34EF535}';

        /// <summary>
        /// Well-known object for Emergency Management Services settings.
        /// </summary>
         DebuggerSettingsGroupId = '{4636856E-540F-4170-A130-A84776F4C654}';

        /// <summary>
        /// Well-known object for NTLDR application.
        /// </summary>
         WindowsLegacyNtldrId = '{466F5A88-0AF2-4F76-9038-095B170DC21C}';

        /// <summary>
        /// Well-known object for bad memory settings.
        /// </summary>
         BadMemoryGroupId = '{5189B25C-5558-4BF2-BCA4-289B11BD29E2}';

        /// <summary>
        /// Well-known object for Boot Loader settings.
        /// </summary>
         BootLoaderSettingsGroupId = '{6EFB52BF-1766-41DB-A6B3-0EE5EFF72BD7}';

        /// <summary>
        /// Well-known object for EFI setup.
        /// </summary>
         WindowsSetupEfiId = '{7254A080-1510-4E85-AC0F-E7FB3D444736}';

        /// <summary>
        /// Well-known object for Global settings.
        /// </summary>
         GlobalSettingsGroupId = '{7EA2E1AC-2E61-4728-AAA3-896D9D0A9F0E}';

        /// <summary>
        /// Well-known object for Windows Boot Manager.
        /// </summary>
         WindowsBootManagerId = '{9DEA862C-5CDD-4E70-ACC1-F32B344D4795}';

        /// <summary>
        /// Well-known object for PCAT Template.
        /// </summary>
         WindowsOsTargetTemplatePcatId = '{A1943BBC-EA85-487C-97C7-C9EDE908A38A}';

        /// <summary>
        /// Well-known object for Firmware Boot Manager.
        /// </summary>
         FirmwareBootManagerId = '{A5A30FA2-3D06-4E9F-B5F4-A01DF9D1FCBA}';

        /// <summary>
        /// Well-known object for Windows Setup RAMDISK options.
        /// </summary>
         WindowsSetupRamdiskOptionsId = '{AE5534E0-A924-466C-B836-758539A3EE3A}';

        /// <summary>
        /// Well-known object for EFI template.
        /// </summary>
         WindowsOsTargetTemplateEfiId = '{B012B84D-C47C-4ED5-B722-C0C42163E569}';

        /// <summary>
        /// Well-known object for Windows memory tester application.
        /// </summary>
         WindowsMemoryTesterId = '{B2721D73-1DB4-4C62-BF78-C548A880142D}';

        /// <summary>
        /// Well-known object for Windows PCAT setup.
        /// </summary>
         WindowsSetupPcatId = '{CBD971BF-B7B8-4885-951A-FA03044F5D71}';

        /// <summary>
        /// Alias for the current boot entry.
        /// </summary>
         CurrentBootEntryId = '{FA926493-6F1C-4193-A414-58F0B2456D1E}';

implementation

end.
